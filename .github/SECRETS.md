# GitHub Secrets Configuration

To enable automated deployments via GitHub Actions, you need to configure the following secrets in your repository.

## Setting Up Secrets

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below

## Required Secrets

### Apps Script Deployment

#### `CLASP_CREDENTIALS`
Your clasp authentication credentials.

**How to get:**
```bash
# Login to clasp if not already
clasp login

# Copy the credentials
cat ~/.clasprc.json
```

Copy the entire JSON content and paste as the secret value.

**Example format:**
```json
{
  "token": {
    "access_token": "ya29...",
    "refresh_token": "1//...",
    "scope": "https://www.googleapis.com/auth/...",
    "token_type": "Bearer",
    "expiry_date": 1234567890000
  },
  "oauth2ClientSettings": {
    "clientId": "...",
    "clientSecret": "...",
    "redirectUri": "http://localhost"
  },
  "isLocalCreds": false
}
```

#### `APPS_SCRIPT_ID`
Your Apps Script project ID.

**How to get:**
```bash
cd apps-script
cat .clasp.json | grep scriptId
```

Or from the URL when editing: `https://script.google.com/d/SCRIPT_ID/edit`

**Example:** `1abc-xyz123_ABC456DEF789`

#### `TEACHER_EMAIL`
Your institutional email address.

**Example:** `andrew.casey@monash.edu`

#### `SHEET_ID`
Your Google Sheets database ID.

**How to get:**
From the sheet URL: `https://docs.google.com/spreadsheets/d/SHEET_ID/edit`

Or from `.env` file after running `npm run create:sheet`

**Example:** `1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms`

### Cloud Function Deployment

#### `GCP_PROJECT_ID`
Your Google Cloud Platform project ID.

**How to get:**
```bash
gcloud config get-value project
```

Or from `.env` file: `GCP_PROJECT_ID=nbd-grading-xxxxx`

**Example:** `nbd-grading-37239`

#### `GCP_REGION`
The region where your Cloud Function is deployed.

**Default:** `us-central1`

Other options: `us-east1`, `europe-west1`, `asia-northeast1`, etc.

#### `GCP_SERVICE_ACCOUNT_KEY`
Service account key for deploying to GCP.

**How to get:**
```bash
# After running setup-gcp.sh
cat credentials/service-account-key.json
```

Copy the entire JSON content and paste as the secret value.

**Example format:**
```json
{
  "type": "service_account",
  "project_id": "nbd-grading-xxxxx",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "nbgrader-function@nbd-grading-xxxxx.iam.gserviceaccount.com",
  "client_id": "123456789...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

⚠️ **Security:** Never commit this file to Git. It's already in `.gitignore`.

### Optional Secrets

#### `CLOUD_FUNCTION_URL`
The deployed Cloud Function URL (auto-populated after first deployment).

You can add this manually after deploying once, or the workflow will display it in the logs.

**Example:** `https://us-central1-nbd-grading-xxxxx.cloudfunctions.net/grade-notebooks`

## Quick Setup Script

Run this script to display all required secret values:

```bash
#!/bin/bash

echo "=== GitHub Secrets Configuration ==="
echo ""

echo "CLASP_CREDENTIALS:"
cat ~/.clasprc.json
echo ""

echo "APPS_SCRIPT_ID:"
cat apps-script/.clasp.json 2>/dev/null | grep scriptId | cut -d'"' -f4 || echo "Not deployed yet"
echo ""

echo "TEACHER_EMAIL:"
grep TEACHER_EMAIL .env | cut -d'=' -f2
echo ""

echo "SHEET_ID:"
grep SHEET_ID .env | cut -d'=' -f2
echo ""

echo "GCP_PROJECT_ID:"
grep GCP_PROJECT_ID .env | cut -d'=' -f2
echo ""

echo "GCP_REGION:"
grep GCP_REGION .env | cut -d'=' -f2
echo ""

echo "GCP_SERVICE_ACCOUNT_KEY:"
cat credentials/service-account-key.json 2>/dev/null || echo "Not created yet - run npm run setup:gcp"
echo ""

echo "CLOUD_FUNCTION_URL:"
grep CLOUD_FUNCTION_URL .env | cut -d'=' -f2
echo ""
```

Save as `scripts/show-secrets.sh`, make executable, and run:

```bash
chmod +x scripts/show-secrets.sh
./scripts/show-secrets.sh
```

## Verification

After adding all secrets, you can verify by:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. You should see all secrets listed (values are hidden)
3. Push a change to trigger the workflows
4. Check **Actions** tab to see deployment progress

## Security Best Practices

- ✅ Secrets are encrypted by GitHub
- ✅ Secrets are not exposed in logs (unless you explicitly echo them)
- ✅ Only repository collaborators can access secrets
- ✅ Use separate service accounts for different environments (dev/prod)
- ✅ Rotate credentials periodically (every 90 days)
- ✅ Use the principle of least privilege for service accounts

## Troubleshooting

### "Secret not found" error
- Check secret name matches exactly (case-sensitive)
- Ensure secret is added to repository settings, not organization settings
- Verify workflow file references correct secret name

### Authentication failures
- Check `CLASP_CREDENTIALS` is valid JSON
- Ensure `GCP_SERVICE_ACCOUNT_KEY` has required permissions
- Verify service account is enabled in GCP Console

### Deployment fails
- Check all required secrets are set
- Verify GCP billing is enabled
- Check Cloud Function logs in GCP Console
- Review GitHub Actions logs for specific error messages
