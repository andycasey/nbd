# Google Cloud Platform Setup Guide

Step-by-step instructions for setting up GCP for the Jupyter Notebook Grading System.

## Prerequisites

- Google account (preferably institutional @monash.edu account)
- Credit card for GCP billing (free tier covers most usage)
- Basic familiarity with terminal/command line

## Part 1: Google Cloud Project Setup

### 1.1 Create GCP Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Project name: `notebook-grading-system` (or your choice)
4. Organization: Select your institution if available
5. Click "Create"
6. Wait for project creation (~30 seconds)

**Note your Project ID** - you'll need this later. It might be different from the project name (e.g., `notebook-grading-system-123456`).

### 1.2 Enable Billing

1. In Cloud Console, go to "Billing" from the navigation menu
2. Link a billing account (or create new one)
3. Enable billing for your project

**Cost estimate:** ~$0.50-$5/month depending on usage. Free tier covers most small courses.

### 1.3 Enable Required APIs

Go to "APIs & Services" → "Library" and enable:

- [x] Google Drive API
- [x] Gmail API
- [x] Cloud Functions API
- [x] Cloud Build API (automatically enabled with Cloud Functions)
- [x] Google Sheets API

**Quick enable via gcloud CLI:**
```bash
gcloud services enable drive.googleapis.com
gcloud services enable gmail.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable sheets.googleapis.com
```

## Part 2: Service Account Setup

Service accounts allow the Cloud Function to access Google Drive on your behalf.

### 2.1 Create Service Account

1. Go to "IAM & Admin" → "Service Accounts"
2. Click "Create Service Account"
3. Service account name: `nbgrader-function`
4. Service account ID: `nbgrader-function` (auto-generated)
5. Description: "Service account for automated notebook grading"
6. Click "Create and Continue"

### 2.2 Grant Permissions

Add these roles:
- **Service Account User** (required to deploy functions)
- **Cloud Functions Developer** (required to manage functions)

Click "Continue" → "Done"

### 2.3 Create Service Account Key

1. Click on the service account you just created
2. Go to "Keys" tab
3. Click "Add Key" → "Create new key"
4. Select "JSON" format
5. Click "Create"
6. **Save the downloaded JSON file securely** - you'll need it for deployment

**Security:** This key grants full access to the service account. Never commit it to Git or share publicly.

## Part 3: OAuth Consent Screen

Required for Apps Script to request Drive access from students.

### 3.1 Configure Consent Screen

1. Go to "APIs & Services" → "OAuth consent screen"
2. User type:
   - Select **Internal** if using Google Workspace (university email)
   - Select **External** if using personal Gmail
3. Click "Create"

### 3.2 Fill App Information

**App information:**
- App name: `Notebook Grading System`
- User support email: `your.email@monash.edu`
- App logo: (optional)

**App domain:**
- Application home page: (leave blank for now)
- Privacy policy: (leave blank or link to university policy)
- Terms of service: (leave blank)

**Authorized domains:**
- Add `script.google.com` (for Apps Script)

**Developer contact:**
- Your email: `your.email@monash.edu`

Click "Save and Continue"

### 3.3 Configure Scopes

Click "Add or Remove Scopes"

Add these scopes:
- `https://www.googleapis.com/auth/drive.file` - Create and access Drive files
- `https://www.googleapis.com/auth/userinfo.email` - View email address
- `https://www.googleapis.com/auth/spreadsheets` - Access Google Sheets

Click "Update" → "Save and Continue"

### 3.4 Test Users (External apps only)

If you selected "External" user type:
1. Click "Add Users"
2. Add your email and a few test student emails
3. Click "Add" → "Save and Continue"

### 3.5 Summary

Review and click "Back to Dashboard"

**For Internal apps:** You're done! All users in your organization can use the app.

**For External apps:** The app is in "Testing" mode. To publish:
1. Click "Publish App" when ready for production
2. Submit for Google verification (if needed)

## Part 4: Google Apps Script Setup

### 4.1 Create Google Sheet for Database

1. Go to [Google Sheets](https://sheets.google.com)
2. Create new spreadsheet
3. Name it: `NBD Database`
4. **Note the Sheet ID** from URL: `https://docs.google.com/spreadsheets/d/SHEET_ID/edit`

The Apps Script will automatically create two sheets:
- `Assignments` - stores assignment metadata
- `Submissions` - tracks student submissions

### 4.2 Create Apps Script Project

1. Go to [Google Apps Script](https://script.google.com)
2. Click "New Project"
3. Name it: `NBD Teacher Dashboard`

### 4.3 Upload Code Files

1. Delete the default `Code.gs` content
2. Copy content from `/apps-script/Code.gs` in this repository
3. Update these constants:
   ```javascript
   const TEACHER_EMAIL = "your.email@monash.edu";
   const ASSIGNMENTS_SHEET_ID = "YOUR_SHEET_ID_HERE";
   ```

4. Add HTML file:
   - Click "+" → "HTML file"
   - Name it: `Dashboard`
   - Copy content from `/apps-script/Dashboard.html`

5. Update `appsscript.json`:
   - Click "Project Settings" (gear icon)
   - Check "Show appsscript.json in editor"
   - Go back to Editor
   - Replace `appsscript.json` with content from `/apps-script/appsscript.json`

### 4.4 Test Setup

1. In Apps Script editor, select function `testSetup` from dropdown
2. Click "Run"
3. First run: Click "Review Permissions" → Select your account → "Allow"
4. Check "Execution log" (View → Logs)
5. Should see: `✓ Setup test passed!`

### 4.5 Deploy Web App

1. Click "Deploy" → "New deployment"
2. Type: "Web app"
3. Description: "Initial deployment"
4. Execute as: **Me (your email)**
5. Who has access: **Anyone**
6. Click "Deploy"
7. **Copy the Web App URL** - this is your dashboard URL
8. Click "Done"

### 4.6 Test Dashboard

1. Open the Web App URL in a new browser tab
2. You should see the teacher dashboard
3. Try creating a test assignment (use any Drive file ID for testing)

## Part 5: Cloud Function Deployment

### 5.1 Install Google Cloud SDK

**macOS:**
```bash
brew install --cask google-cloud-sdk
```

**Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Windows:**
Download from [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)

### 5.2 Authenticate gcloud

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 5.3 Set Environment Variables (Optional)

If you want to use service account key locally:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

**On GCP:** The deployed function will automatically use the project's default credentials.

### 5.4 Deploy Function

```bash
cd /Users/acasey/software/nbd/cloud-function
chmod +x deploy.sh
./deploy.sh YOUR_PROJECT_ID
```

Wait 2-5 minutes for deployment.

### 5.5 Get Function URL

After deployment completes, copy the Function URL from the output.

Example: `https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/grade-notebooks`

### 5.6 Update Apps Script with Function URL

1. Go back to Apps Script editor
2. Open `Code.gs`
3. Find line: `const CLOUD_FUNCTION_URL = "YOUR_CLOUD_FUNCTION_URL_HERE";`
4. Replace with your actual function URL
5. Click "Save" (Ctrl+S / Cmd+S)

### 5.7 Redeploy Apps Script

1. Click "Deploy" → "Manage deployments"
2. Click "Edit" (pencil icon) on your deployment
3. Version: "New version"
4. Description: "Added Cloud Function URL"
5. Click "Deploy"

## Part 6: Verification Testing

### 6.1 Test Full Workflow

**Create test assignment:**

1. Create simple Jupyter notebook with nbgrader cells (see `/notebooks/example-instructor-notebook.ipynb`)
2. Upload to Google Drive
3. Get file ID from Drive URL
4. Open teacher dashboard
5. Create assignment with that file ID
6. Copy generated invite link

**Test student flow:**

1. Open invite link in incognito/private browser (or different Google account)
2. Grant permissions
3. Verify notebook appears in Colab
4. Make changes and save
5. Close Colab

**Check submission recorded:**

1. Back in teacher dashboard, check Submissions sheet
2. Should see student email, timestamp, and file ID

**Test grading (Phase 2):**

1. In dashboard, click "Grade All" for the assignment
2. Check Cloud Function logs: `gcloud functions logs read grade-notebooks --region=us-central1`
3. Wait for email notification
4. Verify CSV download link works

## Troubleshooting

### "Access denied" when students click invite link
- Check OAuth consent screen configuration
- Verify scopes in `appsscript.json`
- Make sure app is published (or students are added as test users)

### Cloud Function deployment fails
- Check that all required APIs are enabled
- Verify service account has correct permissions
- Check Cloud Build logs in GCP console

### Grading fails with "Permission denied"
- Verify service account has access to Drive files
- Check that notebooks are shared with teacher email
- Review Cloud Function logs for detailed error

### Dashboard doesn't load
- Check Apps Script execution logs
- Verify web app deployment settings (Execute as: Me, Access: Anyone)
- Try redeploying

## Security Checklist

- [x] Service account key stored securely (not in Git)
- [x] OAuth consent screen configured with minimal scopes
- [x] Cloud Function authentication configured (allow unauthenticated for Apps Script calls)
- [x] Teacher email verified in all configuration files
- [x] Student data stored only in teacher's Google account
- [x] FERPA compliance: No third-party data sharing

## Cost Monitoring

Set up billing alerts:

1. Go to "Billing" → "Budgets & alerts"
2. Click "Create budget"
3. Budget name: `NBD Monthly Budget`
4. Set amount: $10/month (adjust based on class size)
5. Add alert thresholds: 50%, 90%, 100%
6. Add email notification

## Next Steps

1. Complete [Teacher Quickstart Guide](../docs/teacher-quickstart.md)
2. Create your first real assignment
3. Test with a small group of students
4. Monitor costs and adjust as needed

## Support

- GCP Issues: [cloud.google.com/support](https://cloud.google.com/support)
- Apps Script: [developers.google.com/apps-script/support](https://developers.google.com/apps-script/support)
- nbgrader: [nbgrader.readthedocs.io](https://nbgrader.readthedocs.io/)
