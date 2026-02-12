/**
 * Jupyter Notebook Grading System - Apps Script Backend
 *
 * Handles student notebook distribution via invite links and tracks submissions.
 *
 * Setup:
 * 1. Update TEACHER_EMAIL and ASSIGNMENTS_SHEET_ID constants
 * 2. Deploy as web app with "Execute as: Me" and "Who has access: Anyone"
 * 3. Authorize required OAuth scopes
 */

// ===== CONFIGURATION =====
const TEACHER_EMAIL = "andrew.casey@monash.edu";
const ASSIGNMENTS_SHEET_ID = "YOUR_SHEET_ID_HERE"; // Replace with your Google Sheet ID

// Sheet names
const ASSIGNMENTS_SHEET = "Assignments";
const SUBMISSIONS_SHEET = "Submissions";

// ===== MAIN ENTRY POINTS =====

/**
 * Handle incoming HTTP GET requests (invite links)
 * URL format: https://script.google.com/.../exec?assignment=ASSIGNMENT_ID
 */
function doGet(e) {
  try {
    const assignmentId = e.parameter.assignment;

    if (!assignmentId) {
      return createErrorPage("Missing assignment parameter in URL.");
    }

    const assignment = getAssignment(assignmentId);
    if (!assignment) {
      return createErrorPage("Invalid assignment link. Please contact your instructor.");
    }

    // Get student email from active session
    const userEmail = Session.getActiveUser().getEmail();
    if (!userEmail) {
      return createErrorPage("Please sign in with your Google account and try again.");
    }

    // Check if student already accessed this assignment
    const existing = getSubmission(assignmentId, userEmail);
    if (existing) {
      Logger.log(`Student ${userEmail} returning to assignment ${assignmentId}`);
      return redirectToColab(existing.notebookFileId, "Welcome back!", assignment.name);
    }

    // First-time access: copy notebook to student's Drive
    Logger.log(`New access: ${userEmail} for assignment ${assignmentId}`);

    const templateFile = DriveApp.getFileById(assignment.notebookFileId);
    const studentFolder = getOrCreateStudentFolder(assignment.name);
    const studentNotebook = templateFile.makeCopy(
      `${assignment.name} - ${userEmail}`,
      studentFolder
    );

    // Share with teacher (required for grading)
    studentNotebook.addEditor(TEACHER_EMAIL);

    // Record submission in database
    recordSubmission(assignmentId, userEmail, studentNotebook.getId());

    // Redirect to Colab
    return redirectToColab(studentNotebook.getId(), "Setting up your notebook...", assignment.name);

  } catch (error) {
    Logger.log(`Error in doGet: ${error.toString()}`);
    return createErrorPage(`System error: ${error.toString()}`);
  }
}

/**
 * Handle POST requests (API calls from dashboard)
 */
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const action = data.action;

    switch (action) {
      case 'createAssignment':
        return createAssignment(data);
      case 'getSubmissions':
        return getSubmissions(data.assignmentId);
      case 'gradeAll':
        return gradeAllSubmissions(data.assignmentId);
      default:
        return ContentService.createTextOutput(JSON.stringify({
          error: 'Unknown action'
        })).setMimeType(ContentService.MimeType.JSON);
    }
  } catch (error) {
    Logger.log(`Error in doPost: ${error.toString()}`);
    return ContentService.createTextOutput(JSON.stringify({
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// ===== ASSIGNMENT MANAGEMENT =====

/**
 * Create new assignment and return invite link
 *
 * @param {Object} data - {name: string, notebookFileId: string, deadline: string}
 * @return {Object} {assignmentId: string, inviteUrl: string}
 */
function createAssignment(data) {
  const sheet = openSheet(ASSIGNMENTS_SHEET);
  const assignmentId = Utilities.getUuid();
  const timestamp = new Date().toISOString();

  sheet.appendRow([
    assignmentId,
    data.name,
    data.notebookFileId,
    data.deadline || '',
    timestamp
  ]);

  const inviteUrl = getInviteUrl(assignmentId);

  return ContentService.createTextOutput(JSON.stringify({
    assignmentId: assignmentId,
    inviteUrl: inviteUrl
  })).setMimeType(ContentService.MimeType.JSON);
}

/**
 * Get assignment details by ID
 *
 * @param {string} assignmentId
 * @return {Object|null} {id, name, notebookFileId, deadline}
 */
function getAssignment(assignmentId) {
  const sheet = openSheet(ASSIGNMENTS_SHEET);
  const data = sheet.getDataRange().getValues();

  // Skip header row
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === assignmentId) {
      return {
        id: data[i][0],
        name: data[i][1],
        notebookFileId: data[i][2],
        deadline: data[i][3],
        created: data[i][4]
      };
    }
  }

  return null;
}

/**
 * Generate invite URL for assignment
 *
 * @param {string} assignmentId
 * @return {string} Full URL
 */
function getInviteUrl(assignmentId) {
  const scriptUrl = ScriptApp.getService().getUrl();
  return `${scriptUrl}?assignment=${assignmentId}`;
}

// ===== SUBMISSION TRACKING =====

/**
 * Record student submission in database
 *
 * @param {string} assignmentId
 * @param {string} studentEmail
 * @param {string} notebookFileId
 */
function recordSubmission(assignmentId, studentEmail, notebookFileId) {
  const sheet = openSheet(SUBMISSIONS_SHEET);
  const timestamp = new Date().toISOString();

  sheet.appendRow([
    assignmentId,
    studentEmail,
    notebookFileId,
    timestamp,
    '', // grade (filled later)
    ''  // feedback (filled later)
  ]);

  Logger.log(`Recorded submission: ${studentEmail} for assignment ${assignmentId}`);
}

/**
 * Get existing submission by student
 *
 * @param {string} assignmentId
 * @param {string} studentEmail
 * @return {Object|null} {notebookFileId, timestamp, grade, feedback}
 */
function getSubmission(assignmentId, studentEmail) {
  const sheet = openSheet(SUBMISSIONS_SHEET);
  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === assignmentId && data[i][1] === studentEmail) {
      return {
        notebookFileId: data[i][2],
        timestamp: data[i][3],
        grade: data[i][4],
        feedback: data[i][5]
      };
    }
  }

  return null;
}

/**
 * Get all submissions for an assignment
 *
 * @param {string} assignmentId
 * @return {Array} List of submission objects
 */
function getSubmissions(assignmentId) {
  const sheet = openSheet(SUBMISSIONS_SHEET);
  const data = sheet.getDataRange().getValues();
  const submissions = [];

  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === assignmentId) {
      submissions.push({
        email: data[i][1],
        notebookFileId: data[i][2],
        timestamp: data[i][3],
        grade: data[i][4],
        feedback: data[i][5]
      });
    }
  }

  return ContentService.createTextOutput(JSON.stringify({
    submissions: submissions
  })).setMimeType(ContentService.MimeType.JSON);
}

// ===== GRADING (PHASE 2) =====

/**
 * Trigger Cloud Function to grade all submissions
 *
 * @param {string} assignmentId
 * @return {Object} Status message
 */
function gradeAllSubmissions(assignmentId) {
  const CLOUD_FUNCTION_URL = "YOUR_CLOUD_FUNCTION_URL_HERE"; // Update after deployment

  const assignment = getAssignment(assignmentId);
  const sheet = openSheet(SUBMISSIONS_SHEET);
  const data = sheet.getDataRange().getValues();
  const submissions = [];

  // Collect submissions for this assignment
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === assignmentId) {
      submissions.push({
        email: data[i][1],
        notebookId: data[i][2]
      });
    }
  }

  // Call Cloud Function
  const payload = {
    assignmentId: assignmentId,
    assignmentName: assignment.name,
    instructorNotebookId: assignment.notebookFileId,
    submissions: submissions,
    teacherEmail: TEACHER_EMAIL
  };

  const options = {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  };

  try {
    const response = UrlFetchApp.fetch(CLOUD_FUNCTION_URL, options);
    const result = JSON.parse(response.getContentText());

    return ContentService.createTextOutput(JSON.stringify({
      status: 'success',
      message: `Grading ${submissions.length} submissions. You will receive an email when complete.`
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    Logger.log(`Error calling Cloud Function: ${error.toString()}`);
    return ContentService.createTextOutput(JSON.stringify({
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// ===== UTILITY FUNCTIONS =====

/**
 * Open Google Sheet by name, create if doesn't exist
 *
 * @param {string} sheetName
 * @return {Sheet}
 */
function openSheet(sheetName) {
  const ss = SpreadsheetApp.openById(ASSIGNMENTS_SHEET_ID);
  let sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    sheet = ss.insertSheet(sheetName);

    // Add headers based on sheet type
    if (sheetName === ASSIGNMENTS_SHEET) {
      sheet.appendRow(['Assignment ID', 'Name', 'Notebook File ID', 'Deadline', 'Created']);
    } else if (sheetName === SUBMISSIONS_SHEET) {
      sheet.appendRow(['Assignment ID', 'Student Email', 'Notebook File ID', 'Timestamp', 'Grade', 'Feedback']);
    }
  }

  return sheet;
}

/**
 * Get or create folder in student's Drive
 *
 * @param {string} assignmentName
 * @return {Folder}
 */
function getOrCreateStudentFolder(assignmentName) {
  const rootFolderName = "Course Assignments";
  let rootFolder;

  // Check if root folder exists
  const folders = DriveApp.getFoldersByName(rootFolderName);
  if (folders.hasNext()) {
    rootFolder = folders.next();
  } else {
    rootFolder = DriveApp.createFolder(rootFolderName);
  }

  // Check if assignment subfolder exists
  const subfolders = rootFolder.getFoldersByName(assignmentName);
  if (subfolders.hasNext()) {
    return subfolders.next();
  } else {
    return rootFolder.createFolder(assignmentName);
  }
}

/**
 * Create HTML page that redirects to Colab
 *
 * @param {string} notebookId - Google Drive file ID
 * @param {string} message - Message to show before redirect
 * @param {string} assignmentName - Name of assignment
 * @return {HtmlOutput}
 */
function redirectToColab(notebookId, message, assignmentName) {
  const colabUrl = `https://colab.research.google.com/drive/${notebookId}`;

  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <title>Opening Notebook</title>
        <style>
          body {
            font-family: 'Google Sans', Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          }
          .container {
            text-align: center;
            background: white;
            padding: 50px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 500px;
          }
          h1 {
            color: #333;
            margin-bottom: 20px;
          }
          .assignment-name {
            font-size: 18px;
            color: #666;
            margin-bottom: 20px;
          }
          .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 30px auto;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          .message {
            color: #666;
            margin-top: 20px;
          }
          a {
            color: #667eea;
            text-decoration: none;
          }
          a:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>${message}</h1>
          ${assignmentName ? `<div class="assignment-name">${assignmentName}</div>` : ''}
          <div class="spinner"></div>
          <p class="message">Redirecting to Google Colab...</p>
          <p class="message">If you're not redirected, <a href="${colabUrl}" target="_blank">click here</a></p>
        </div>
        <script>
          setTimeout(() => {
            window.location.href = "${colabUrl}";
          }, 2000);
        </script>
      </body>
    </html>
  `;

  return HtmlService.createHtmlOutput(html)
    .setTitle('Opening Notebook')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/**
 * Create error page
 *
 * @param {string} errorMessage
 * @return {HtmlOutput}
 */
function createErrorPage(errorMessage) {
  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <title>Error</title>
        <style>
          body {
            font-family: 'Google Sans', Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: #f5f5f5;
          }
          .container {
            text-align: center;
            background: white;
            padding: 50px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            max-width: 500px;
          }
          h1 {
            color: #d32f2f;
            margin-bottom: 20px;
          }
          p {
            color: #666;
            line-height: 1.6;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>⚠️ Error</h1>
          <p>${errorMessage}</p>
        </div>
      </body>
    </html>
  `;

  return HtmlService.createHtmlOutput(html)
    .setTitle('Error')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/**
 * Test function to verify setup
 */
function testSetup() {
  Logger.log('Testing setup...');
  Logger.log('Teacher email: ' + TEACHER_EMAIL);
  Logger.log('Sheet ID: ' + ASSIGNMENTS_SHEET_ID);

  try {
    const sheet = openSheet(ASSIGNMENTS_SHEET);
    Logger.log('✓ Assignments sheet accessible');

    const submissionsSheet = openSheet(SUBMISSIONS_SHEET);
    Logger.log('✓ Submissions sheet accessible');

    Logger.log('✓ Setup test passed!');
  } catch (error) {
    Logger.log('✗ Setup test failed: ' + error.toString());
  }
}
