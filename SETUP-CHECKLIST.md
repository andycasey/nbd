# Setup Checklist

Use this checklist to track your progress through the initial setup.

## Prerequisites

- [ ] Google account (institutional email preferred)
- [ ] Credit card for GCP billing
- [ ] Terminal/command line access
- [ ] Text editor (VS Code, Sublime, etc.)

## Phase 1: GCP Setup (30-45 minutes)

### Google Cloud Project

- [ ] Created GCP project at console.cloud.google.com
- [ ] Noted Project ID: `______________________`
- [ ] Enabled billing
- [ ] Enabled Drive API
- [ ] Enabled Gmail API
- [ ] Enabled Cloud Functions API
- [ ] Enabled Sheets API

### Service Account

- [ ] Created service account: `nbgrader-function`
- [ ] Granted Service Account User role
- [ ] Granted Cloud Functions Developer role
- [ ] Downloaded service account key JSON
- [ ] Stored key securely (NOT in Git!)

### OAuth Consent Screen

- [ ] Configured OAuth consent screen
- [ ] App name: `Notebook Grading System`
- [ ] Added required scopes:
  - [ ] `drive.file`
  - [ ] `userinfo.email`
  - [ ] `spreadsheets`
- [ ] Published app (or added test users)

## Phase 2: Google Sheets Database (5 minutes)

- [ ] Created new Google Sheet
- [ ] Named it: `NBD Database`
- [ ] Noted Sheet ID: `______________________`
- [ ] Kept it accessible (will auto-create tabs)

## Phase 3: Apps Script Deployment (20-30 minutes)

### Setup

- [ ] Created new Apps Script project
- [ ] Named it: `NBD Teacher Dashboard`
- [ ] Copied `Code.gs` content
- [ ] Updated `TEACHER_EMAIL` constant: `______________________`
- [ ] Updated `ASSIGNMENTS_SHEET_ID` constant
- [ ] Created `Dashboard.html` file
- [ ] Copied Dashboard.html content
- [ ] Updated `appsscript.json` with correct scopes

### Testing

- [ ] Ran `testSetup()` function
- [ ] Authorized OAuth scopes
- [ ] Verified setup test passed
- [ ] Checked that sheets were created in database

### Deployment

- [ ] Deployed as web app
- [ ] Execute as: **Me**
- [ ] Access: **Anyone**
- [ ] Noted Web App URL: `______________________`
- [ ] Tested dashboard loads in browser
- [ ] Created test assignment (with dummy file ID)

## Phase 4: Local nbgrader Setup (15 minutes)

- [ ] Installed Python (3.8 or later)
- [ ] Installed nbgrader: `pip install nbgrader`
- [ ] Created course directory: `~/my-course`
- [ ] Ran `nbgrader quickstart my-course`
- [ ] Edited `nbgrader_config.py`
- [ ] Tested nbgrader with example notebook

## Phase 5: Cloud Function Deployment (20-30 minutes)

### Prerequisites

- [ ] Installed Google Cloud SDK
- [ ] Authenticated: `gcloud auth login`
- [ ] Set project: `gcloud config set project PROJECT_ID`

### Deployment

- [ ] Navigated to `/cloud-function` directory
- [ ] Reviewed `deploy.sh` script
- [ ] Updated PROJECT_ID in deploy.sh (or passed as argument)
- [ ] Ran deployment: `./deploy.sh PROJECT_ID`
- [ ] Noted Function URL: `______________________`
- [ ] Verified deployment in GCP Console

### Integration

- [ ] Updated `Code.gs` with Cloud Function URL
- [ ] Looked for: `const CLOUD_FUNCTION_URL = "..."`
- [ ] Saved changes
- [ ] Redeployed Apps Script
- [ ] Created new version

## Phase 6: End-to-End Testing (30-45 minutes)

### Create Test Assignment

- [ ] Created simple test notebook with nbgrader
- [ ] Used example-instructor-notebook.ipynb as template
- [ ] Validated notebook: `nbgrader validate source/test/test.ipynb`
- [ ] Generated student version: `nbgrader generate_assignment test`
- [ ] Uploaded student version to Google Drive
- [ ] Noted Drive file ID

### Test Student Flow

- [ ] Created assignment in dashboard
- [ ] Copied invite link
- [ ] Opened link in incognito/different account
- [ ] Granted permissions
- [ ] Verified notebook copied to student Drive
- [ ] Verified notebook opened in Colab
- [ ] Made test changes and saved
- [ ] Closed Colab

### Verify Tracking

- [ ] Checked Submissions sheet
- [ ] Found student email and timestamp
- [ ] Verified notebook file ID recorded

### Test Grading (Phase 2)

- [ ] Created 2-3 test student submissions
- [ ] Clicked "Grade All" in dashboard
- [ ] Waited for email notification
- [ ] Received email with CSV link (2-5 minutes)
- [ ] Downloaded CSV
- [ ] Verified grades match expectations

## Phase 7: Production Readiness

### Security

- [ ] Verified .gitignore excludes credentials
- [ ] Confirmed service account key NOT in Git
- [ ] Reviewed OAuth scopes (minimal required)
- [ ] Set up billing alerts in GCP

### Documentation

- [ ] Read teacher quickstart guide
- [ ] Bookmarked dashboard URL
- [ ] Saved Cloud Function URL
- [ ] Documented any customizations

### Communication

- [ ] Drafted student announcement email
- [ ] Prepared troubleshooting contact info
- [ ] Planned office hours for first assignment

## Ready to Launch! 🚀

- [ ] Created first real assignment
- [ ] Generated invite link
- [ ] Shared with students via LMS
- [ ] Monitoring submissions in dashboard

## Troubleshooting

If you encounter issues, check:

1. **Students can't access invite link:**
   - OAuth consent screen published?
   - Correct scopes in appsscript.json?
   - Web app deployed with "Anyone" access?

2. **Grading fails:**
   - Cloud Function logs: `gcloud functions logs read grade-notebooks`
   - Check service account permissions
   - Verify notebooks shared with teacher

3. **Dashboard errors:**
   - Apps Script execution logs: View → Logs
   - Verify Sheet ID is correct
   - Check OAuth authorization

## Support Resources

- **GCP Setup:** [setup/gcp-setup.md](setup/gcp-setup.md)
- **Teacher Guide:** [docs/teacher-quickstart.md](docs/teacher-quickstart.md)
- **nbgrader Docs:** https://nbgrader.readthedocs.io/
- **Apps Script Docs:** https://developers.google.com/apps-script

## Notes

Use this space for your own notes and customizations:

```
[Your notes here]
```
