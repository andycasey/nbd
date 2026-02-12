#!/usr/bin/env python3
"""
Create Google Sheet for NBD Database
"""

import os
import sys
from googleapiclient.discovery import build
from google.auth import default

def create_sheet():
    """Create NBD Database Google Sheet with proper structure"""

    # Get credentials
    print("Authenticating with Google...")
    creds, project = default()

    # Build services
    sheets_service = build('sheets', 'v4', credentials=creds)
    drive_service = build('drive', 'v3', credentials=creds)

    # Create spreadsheet
    print("Creating spreadsheet...")
    spreadsheet = {
        'properties': {
            'title': 'NBD Database'
        },
        'sheets': [
            {
                'properties': {
                    'title': 'Assignments',
                    'gridProperties': {
                        'rowCount': 1000,
                        'columnCount': 10,
                        'frozenRowCount': 1
                    }
                }
            },
            {
                'properties': {
                    'title': 'Submissions',
                    'gridProperties': {
                        'rowCount': 10000,
                        'columnCount': 10,
                        'frozenRowCount': 1
                    }
                }
            }
        ]
    }

    result = sheets_service.spreadsheets().create(body=spreadsheet).execute()
    sheet_id = result['spreadsheetId']

    print(f"✓ Created spreadsheet: {sheet_id}")

    # Add headers to Assignments sheet
    print("Adding headers to Assignments sheet...")
    assignments_headers = [[
        'Assignment ID',
        'Name',
        'Notebook File ID',
        'Deadline',
        'Created'
    ]]

    sheets_service.spreadsheets().values().update(
        spreadsheetId=sheet_id,
        range='Assignments!A1:E1',
        valueInputOption='RAW',
        body={'values': assignments_headers}
    ).execute()

    # Add headers to Submissions sheet
    print("Adding headers to Submissions sheet...")
    submissions_headers = [[
        'Assignment ID',
        'Student Email',
        'Notebook File ID',
        'Timestamp',
        'Grade',
        'Feedback'
    ]]

    sheets_service.spreadsheets().values().update(
        spreadsheetId=sheet_id,
        range='Submissions!A1:F1',
        valueInputOption='RAW',
        body={'values': submissions_headers}
    ).execute()

    # Format headers (bold)
    print("Formatting headers...")
    assignments_sheet_id = result['sheets'][0]['properties']['sheetId']
    submissions_sheet_id = result['sheets'][1]['properties']['sheetId']

    requests = [
        {
            'repeatCell': {
                'range': {
                    'sheetId': assignments_sheet_id,
                    'startRowIndex': 0,
                    'endRowIndex': 1
                },
                'cell': {
                    'userEnteredFormat': {
                        'textFormat': {'bold': True},
                        'backgroundColor': {'red': 0.9, 'green': 0.9, 'blue': 0.9}
                    }
                },
                'fields': 'userEnteredFormat(textFormat,backgroundColor)'
            }
        },
        {
            'repeatCell': {
                'range': {
                    'sheetId': submissions_sheet_id,
                    'startRowIndex': 0,
                    'endRowIndex': 1
                },
                'cell': {
                    'userEnteredFormat': {
                        'textFormat': {'bold': True},
                        'backgroundColor': {'red': 0.9, 'green': 0.9, 'blue': 0.9}
                    }
                },
                'fields': 'userEnteredFormat(textFormat,backgroundColor)'
            }
        }
    ]

    sheets_service.spreadsheets().batchUpdate(
        spreadsheetId=sheet_id,
        body={'requests': requests}
    ).execute()

    print(f"\n✅ Sheet created successfully!")
    print(f"Sheet ID: {sheet_id}")
    print(f"URL: https://docs.google.com/spreadsheets/d/{sheet_id}")

    # Update .env file
    env_file = '.env'
    if os.path.exists(env_file):
        print(f"\nUpdating {env_file}...")
        with open(env_file, 'r') as f:
            lines = f.readlines()

        with open(env_file, 'w') as f:
            updated = False
            for line in lines:
                if line.startswith('SHEET_ID='):
                    f.write(f'SHEET_ID={sheet_id}\n')
                    updated = True
                else:
                    f.write(line)

            if not updated:
                # Add at the end if not found
                f.write(f'\nSHEET_ID={sheet_id}\n')

        print(f"✅ Updated {env_file} with SHEET_ID")
    else:
        print(f"\n⚠️  No .env file found")
        print(f"Add this to your .env file:")
        print(f"SHEET_ID={sheet_id}")

    return sheet_id

if __name__ == '__main__':
    try:
        sheet_id = create_sheet()
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
