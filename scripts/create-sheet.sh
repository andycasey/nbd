#!/bin/bash

# Create Google Sheet for NBD Database
# Uses Google Sheets API via gcloud

set -e

echo "📊 Creating NBD Database Google Sheet"
echo "======================================"

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

SHEET_NAME="NBD Database"

# Check if we have Python and google-api-python-client
if ! python3 -c "import googleapiclient" &>/dev/null; then
    echo "Installing Google API Python client..."
    pip3 install --quiet google-api-python-client google-auth-httplib2 google-auth-oauthlib
fi

# Create sheet using Python script
python3 - <<EOF
import os
import json
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
import pickle

SCOPES = ['https://www.googleapis.com/auth/spreadsheets',
          'https://www.googleapis.com/auth/drive.file']

def get_credentials():
    creds = None
    # Check if we have a token file
    if os.path.exists('.google-creds.pickle'):
        with open('.google-creds.pickle', 'rb') as token:
            creds = pickle.load(token)

    # If there are no valid credentials, use gcloud auth
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            # Use gcloud application-default login
            print("Please authenticate with Google:")
            print("Run: gcloud auth application-default login")
            print("Then re-run this script")
            exit(1)

    return creds

def create_sheet():
    creds = get_credentials()
    service = build('sheets', 'v4', credentials=creds)

    # Create spreadsheet
    spreadsheet = {
        'properties': {
            'title': '$SHEET_NAME'
        },
        'sheets': [
            {
                'properties': {
                    'title': 'Assignments',
                    'gridProperties': {
                        'rowCount': 1000,
                        'columnCount': 10
                    }
                }
            },
            {
                'properties': {
                    'title': 'Submissions',
                    'gridProperties': {
                        'rowCount': 10000,
                        'columnCount': 10
                    }
                }
            }
        ]
    }

    result = service.spreadsheets().create(body=spreadsheet).execute()
    sheet_id = result['spreadsheetId']

    # Add headers to Assignments sheet
    assignments_headers = [
        ['Assignment ID', 'Name', 'Notebook File ID', 'Deadline', 'Created']
    ]

    service.spreadsheets().values().update(
        spreadsheetId=sheet_id,
        range='Assignments!A1:E1',
        valueInputOption='RAW',
        body={'values': assignments_headers}
    ).execute()

    # Add headers to Submissions sheet
    submissions_headers = [
        ['Assignment ID', 'Student Email', 'Notebook File ID', 'Timestamp', 'Grade', 'Feedback']
    ]

    service.spreadsheets().values().update(
        spreadsheetId=sheet_id,
        range='Submissions!A1:F1',
        valueInputOption='RAW',
        body={'values': submissions_headers}
    ).execute()

    print(f"✅ Sheet created successfully!")
    print(f"Sheet ID: {sheet_id}")
    print(f"URL: https://docs.google.com/spreadsheets/d/{sheet_id}")

    # Update .env file
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            lines = f.readlines()

        with open('.env', 'w') as f:
            updated = False
            for line in lines:
                if line.startswith('SHEET_ID='):
                    f.write(f'SHEET_ID={sheet_id}\n')
                    updated = True
                else:
                    f.write(line)

            if not updated:
                f.write(f'\nSHEET_ID={sheet_id}\n')

        print(f"✅ Updated .env file with SHEET_ID")
    else:
        print(f"\n⚠️  No .env file found. Add this to your .env:")
        print(f"SHEET_ID={sheet_id}")

if __name__ == '__main__':
    create_sheet()
EOF

echo ""
echo "Next: Deploy Apps Script with 'npm run deploy:apps-script'"
