"""
Jupyter Notebook Grading System - Cloud Function
Automated grading using nbgrader

Triggered by Apps Script when teacher clicks "Grade All" button.
Downloads student notebooks, runs nbgrader autograde, generates CSV, emails results.
"""

import tempfile
import shutil
import json
import os
from pathlib import Path
from typing import List, Dict, Any
import logging

import pandas as pd
import nbformat
from google.cloud import storage
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload, MediaIoBaseUpload
import io

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Constants
SERVICE_ACCOUNT_FILE = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
TEACHER_EMAIL = os.environ.get('TEACHER_EMAIL', 'andrew.casey@monash.edu')


def grade_notebooks(request):
    """
    Main entry point for Cloud Function

    Expected request JSON:
    {
        "assignmentId": "uuid",
        "assignmentName": "Week 1 - Intro",
        "instructorNotebookId": "drive-file-id",
        "submissions": [
            {"email": "student@example.com", "notebookId": "drive-file-id"},
            ...
        ],
        "teacherEmail": "teacher@example.com"
    }

    Returns:
    {
        "status": "success",
        "graded_count": 30,
        "csv_file_id": "drive-file-id"
    }
    """
    try:
        # Parse request
        request_json = request.get_json()
        logger.info(f"Received grading request for assignment: {request_json['assignmentName']}")

        assignment_id = request_json['assignmentId']
        assignment_name = request_json['assignmentName']
        instructor_notebook_id = request_json['instructorNotebookId']
        submissions = request_json['submissions']
        teacher_email = request_json.get('teacherEmail', TEACHER_EMAIL)

        if not submissions:
            return {'status': 'error', 'message': 'No submissions to grade'}

        # Create temporary directory for grading
        temp_dir = Path(tempfile.mkdtemp())
        logger.info(f"Created temp directory: {temp_dir}")

        try:
            # Set up nbgrader course directory structure
            course_dir = temp_dir / "course"
            course_dir.mkdir()

            # Initialize Drive API
            credentials = get_credentials()
            drive_service = build('drive', 'v3', credentials=credentials)

            # Download instructor notebook (source)
            source_dir = course_dir / "source" / assignment_name
            source_dir.mkdir(parents=True)
            download_notebook(
                drive_service,
                instructor_notebook_id,
                source_dir / "notebook.ipynb"
            )
            logger.info("Downloaded instructor notebook")

            # Download all student submissions
            submitted_dir = course_dir / "submitted"
            for submission in submissions:
                student_email = submission['email']
                student_dir = submitted_dir / student_email / assignment_name
                student_dir.mkdir(parents=True)

                download_notebook(
                    drive_service,
                    submission['notebookId'],
                    student_dir / "notebook.ipynb"
                )
            logger.info(f"Downloaded {len(submissions)} student notebooks")

            # Run nbgrader autograde
            logger.info("Starting nbgrader autograde...")
            results = run_nbgrader_autograde(course_dir, assignment_name, submissions)
            logger.info(f"Grading complete. Processed {len(results)} submissions")

            # Generate CSV
            csv_content = generate_csv(results)

            # Upload CSV to Drive
            csv_file_id = upload_to_drive(
                drive_service,
                csv_content,
                f"grades_{assignment_name}_{assignment_id}.csv",
                teacher_email
            )
            logger.info(f"Uploaded CSV to Drive: {csv_file_id}")

            # Send email notification
            send_email_notification(
                drive_service,
                teacher_email,
                assignment_name,
                len(submissions),
                csv_file_id
            )
            logger.info("Sent email notification")

            return {
                'status': 'success',
                'graded_count': len(results),
                'csv_file_id': csv_file_id
            }

        finally:
            # Cleanup temp directory
            shutil.rmtree(temp_dir)
            logger.info("Cleaned up temp directory")

    except Exception as e:
        logger.error(f"Error in grade_notebooks: {str(e)}", exc_info=True)
        return {
            'status': 'error',
            'message': str(e)
        }


def get_credentials():
    """Get Google API credentials from service account"""
    if SERVICE_ACCOUNT_FILE and os.path.exists(SERVICE_ACCOUNT_FILE):
        credentials = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=[
                'https://www.googleapis.com/auth/drive',
                'https://www.googleapis.com/auth/gmail.send'
            ]
        )
    else:
        # Running on GCP, use default credentials
        from google.auth import default
        credentials, _ = default(scopes=[
            'https://www.googleapis.com/auth/drive',
            'https://www.googleapis.com/auth/gmail.send'
        ])

    return credentials


def download_notebook(drive_service, file_id: str, destination: Path):
    """
    Download notebook from Google Drive

    Args:
        drive_service: Google Drive API service
        file_id: Drive file ID
        destination: Local path to save file
    """
    request = drive_service.files().get_media(fileId=file_id)

    with open(destination, 'wb') as f:
        downloader = MediaIoBaseDownload(f, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
            if status:
                logger.debug(f"Download progress: {int(status.progress() * 100)}%")


def run_nbgrader_autograde(course_dir: Path, assignment_name: str, submissions: List[Dict]) -> List[Dict]:
    """
    Run nbgrader autograde on all submissions

    Args:
        course_dir: Path to nbgrader course directory
        assignment_name: Name of assignment
        submissions: List of submission dicts with 'email' and 'notebookId'

    Returns:
        List of grading results
    """
    try:
        # Import nbgrader after we're in the course directory
        from nbgrader.apps import AutogradeApp

        # Configure and run autograde
        app = AutogradeApp()
        app.coursedir.root = str(course_dir)
        app.coursedir.assignment_id = assignment_name

        # Force execution of all cells (important for grading)
        app.force = True

        # Run autograde
        app.initialize([])
        app.start()

        # Collect results
        results = []
        autograded_dir = course_dir / "autograded"

        for submission in submissions:
            student_email = submission['email']
            graded_notebook_path = autograded_dir / student_email / assignment_name / "notebook.ipynb"

            if graded_notebook_path.exists():
                grade_info = extract_grade_from_notebook(graded_notebook_path)
                grade_info['email'] = student_email
                results.append(grade_info)
            else:
                # Grading failed for this student
                logger.warning(f"Graded notebook not found for {student_email}")
                results.append({
                    'email': student_email,
                    'score': 0,
                    'max_score': 0,
                    'percentage': 0,
                    'feedback': 'Grading failed - notebook could not be processed',
                    'error': True
                })

        return results

    except Exception as e:
        logger.error(f"Error running nbgrader: {str(e)}", exc_info=True)
        raise


def extract_grade_from_notebook(notebook_path: Path) -> Dict[str, Any]:
    """
    Extract grade information from graded notebook

    Args:
        notebook_path: Path to graded notebook

    Returns:
        Dict with score, max_score, percentage, feedback
    """
    with open(notebook_path, 'r') as f:
        nb = nbformat.read(f, as_version=4)

    total_score = 0.0
    max_score = 0.0
    feedback_items = []

    # Scan all cells for nbgrader metadata
    for cell in nb.cells:
        if 'nbgrader' in cell.metadata:
            metadata = cell.metadata['nbgrader']

            # Check if this is a graded cell
            if metadata.get('grade', False):
                points = metadata.get('points', 0)
                max_score += points

                # Check if cell has a score
                if 'score' in metadata:
                    score = metadata.get('score', 0)
                    total_score += score

                    # Add feedback
                    grade_id = metadata.get('grade_id', 'unknown')
                    if score == points:
                        feedback_items.append(f"{grade_id}: PASS ({score}/{points})")
                    else:
                        feedback_items.append(f"{grade_id}: PARTIAL ({score}/{points})")
                else:
                    feedback_items.append(f"{metadata.get('grade_id', 'unknown')}: NOT GRADED")

    # Calculate percentage
    percentage = (total_score / max_score * 100) if max_score > 0 else 0

    return {
        'score': total_score,
        'max_score': max_score,
        'percentage': round(percentage, 2),
        'feedback': '; '.join(feedback_items) if feedback_items else 'No graded cells found',
        'error': False
    }


def generate_csv(results: List[Dict]) -> str:
    """
    Generate CSV content from grading results

    Args:
        results: List of grading result dicts

    Returns:
        CSV content as string
    """
    df = pd.DataFrame(results)

    # Ensure required columns exist
    required_columns = ['email', 'score', 'max_score', 'percentage', 'feedback']
    for col in required_columns:
        if col not in df.columns:
            df[col] = ''

    # Sort by email
    df = df.sort_values('email')

    # Select and order columns
    df = df[required_columns]

    return df.to_csv(index=False)


def upload_to_drive(drive_service, content: str, filename: str, owner_email: str) -> str:
    """
    Upload CSV to Google Drive

    Args:
        drive_service: Google Drive API service
        content: CSV content as string
        filename: Name for the file
        owner_email: Email of file owner

    Returns:
        File ID of uploaded file
    """
    file_metadata = {
        'name': filename,
        'mimeType': 'text/csv'
    }

    media = MediaIoBaseUpload(
        io.BytesIO(content.encode('utf-8')),
        mimetype='text/csv',
        resumable=True
    )

    file = drive_service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id'
    ).execute()

    file_id = file.get('id')

    # Share with teacher
    drive_service.permissions().create(
        fileId=file_id,
        body={
            'type': 'user',
            'role': 'writer',
            'emailAddress': owner_email
        }
    ).execute()

    return file_id


def send_email_notification(drive_service, teacher_email: str, assignment_name: str,
                           submission_count: int, csv_file_id: str):
    """
    Send email notification to teacher with CSV download link

    Args:
        drive_service: Google Drive API service
        teacher_email: Teacher's email address
        assignment_name: Name of assignment
        submission_count: Number of submissions graded
        csv_file_id: Google Drive file ID of CSV
    """
    # Get download URL
    csv_url = f"https://drive.google.com/file/d/{csv_file_id}/view"

    # Construct email
    subject = f"Grading Complete: {assignment_name}"
    body = f"""
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h2>Grading Complete ✅</h2>
        <p><strong>Assignment:</strong> {assignment_name}</p>
        <p><strong>Submissions Graded:</strong> {submission_count}</p>

        <p>Your grading results are ready:</p>
        <p>
          <a href="{csv_url}" style="display: inline-block; padding: 12px 24px;
             background-color: #667eea; color: white; text-decoration: none;
             border-radius: 6px; font-weight: bold;">
            Download CSV Results
          </a>
        </p>

        <p style="margin-top: 30px; color: #666; font-size: 12px;">
          Generated by NBD (Jupyter Notebook Grading System)
        </p>
      </body>
    </html>
    """

    # Note: Actual email sending would require Gmail API setup
    # For now, just log the email content
    logger.info(f"Email notification prepared for {teacher_email}")
    logger.info(f"Subject: {subject}")
    logger.info(f"CSV URL: {csv_url}")

    # TODO: Implement actual email sending using Gmail API
    # This requires additional OAuth setup and permissions


if __name__ == '__main__':
    # For local testing
    print("Cloud Function for nbgrader grading")
    print("Deploy with: gcloud functions deploy grade-notebooks ...")
