# Deployment Guide

Complete guide for deploying the NBD (Jupyter Notebook Grading System) from scratch.

## Overview

This guide covers three deployment approaches:

1. **Manual Local Deployment** - Full control, run everything from command line
2. **Automated Script Deployment** - Use npm scripts for simplified deployment
3. **GitHub Actions CI/CD** - Fully automated deployment on git push

## Prerequisites

- [ ] Google account (institutional email recommended)
- [ ] GCP billing account set up
- [ ] GitHub account
- [ ] Local tools installed:
  - Node.js 14+ (`node --version`)
  - Python 3.8+ (`python3 --version`)
  - gcloud CLI (`gcloud --version`)
  - clasp (`clasp --version` or `npm install -g @google/clasp`)
  - gh CLI (`gh --version`)

## Approach 1: Manual Local Deployment

### Step 1: Clone and Configure

```bash
# Clone repository
git clone https://github.com/andycasey/nbd.git
cd nbd

# Create environment file
cp .env.template .env

# Edit .env with your details
# Required: GCP_PROJECT_ID, TEACHER_EMAIL
nano .env  # or use your preferred editor
```

### Step 2: Set Up GCP

```bash
# Login to gcloud
gcloud auth login

# Create project (or use existing)
PROJECT_ID="nbd-grading-$(date +%s | tail -c 6)"
gcloud projects create $PROJECT_ID --name="Notebook Grading System"

# Set active project
gcloud config set project $PROJECT_ID

# Enable billing (manual step in console)
echo "Enable billing at: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"

# After billing is enabled, enable APIs
gcloud services enable \
  drive.googleapis.com \
  gmail.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  sheets.googleapis.com

# Create service account
gcloud iam service-accounts create nbgrader-function \
  --display-name="NBGrader Cloud Function"

# Grant permissions
SA_EMAIL="nbgrader-function@$PROJECT_ID.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudfunctions.developer"

# Create service account key
mkdir -p credentials
gcloud iam service-accounts keys create credentials/service-account-key.json \
  --iam-account=$SA_EMAIL

# Update .env
echo "GCP_PROJECT_ID=$PROJECT_ID" >> .env
```

### Step 3: Create Google Sheet

```bash
# Option A: Manual
# 1. Go to https://sheets.google.com
# 2. Create new spreadsheet named "NBD Database"
# 3. Copy sheet ID from URL
# 4. Add to .env: SHEET_ID=your_sheet_id

# Option B: Automated (requires additional setup)
npm run create:sheet
```

### Step 4: Deploy Apps Script

```bash
# Login to clasp
clasp login

# Navigate to apps-script directory
cd apps-script

# Update configuration
sed -i '' "s/YOUR_SHEET_ID_HERE/$SHEET_ID/" Code.gs
sed -i '' "s/andrew.casey@monash.edu/$TEACHER_EMAIL/" Code.gs

# Create Apps Script project
clasp create --type webapp --title "NBD Teacher Dashboard"

# Push code
clasp push

# Deploy
clasp deploy --description "Initial deployment"

# Get web app URL (manual step)
echo "Deploy as web app at: https://script.google.com/home"
echo "Execute as: Me, Access: Anyone"
echo "Copy URL to .env as WEB_APP_URL"

cd ..
```

### Step 5: Deploy Cloud Function

```bash
cd cloud-function

gcloud functions deploy grade-notebooks \
  --gen2 \
  --runtime=python311 \
  --region=us-central1 \
  --source=. \
  --entry-point=grade_notebooks \
  --trigger-http \
  --allow-unauthenticated \
  --memory=1024MB \
  --timeout=540s \
  --set-env-vars TEACHER_EMAIL=$TEACHER_EMAIL

# Get function URL
FUNCTION_URL=$(gcloud functions describe grade-notebooks \
  --region=us-central1 \
  --gen2 \
  --format='value(serviceConfig.uri)')

echo "Function URL: $FUNCTION_URL"
echo "Add to .env: CLOUD_FUNCTION_URL=$FUNCTION_URL"

cd ..
```

### Step 6: Update and Redeploy Apps Script

```bash
# Update Code.gs with function URL
cd apps-script
sed -i '' "s|YOUR_CLOUD_FUNCTION_URL_HERE|$CLOUD_FUNCTION_URL|" Code.gs

# Push updated code
clasp push

# Create new deployment
clasp deploy --description "Added Cloud Function URL"

cd ..
```

### Step 7: Test

```bash
# Open dashboard
echo "Dashboard: $WEB_APP_URL"

# Create test assignment
# 1. Upload example notebook to Drive
# 2. Get file ID
# 3. Create assignment in dashboard
# 4. Copy invite link
# 5. Test with different Google account
```

## Approach 2: Automated Script Deployment

Much simpler! After initial setup:

```bash
# Clone and configure
git clone https://github.com/andycasey/nbd.git
cd nbd
cp .env.template .env
# Edit .env

# Run complete setup (requires manual billing enablement)
npm run setup:gcp    # GCP setup with prompts
npm run create:sheet # Create Google Sheet
npm run deploy:all   # Deploy both Apps Script and Cloud Function
```

Individual commands:
```bash
npm run setup:gcp              # Set up GCP project
npm run create:sheet           # Create Google Sheet database
npm run deploy:apps-script     # Deploy Apps Script only
npm run deploy:cloud-function  # Deploy Cloud Function only
npm run deploy:all             # Deploy both
```

## Approach 3: GitHub Actions CI/CD (Recommended for Production)

After initial manual setup, all future deployments are automatic.

### Initial Setup

1. **Complete Approach 1 or 2 first** to get all credentials and IDs

2. **Configure GitHub Secrets**:

```bash
# Display all secret values
./scripts/show-secrets.sh

# Go to GitHub repository
# Settings → Secrets → Actions → New repository secret

# Add each secret shown by the script:
# - CLASP_CREDENTIALS
# - APPS_SCRIPT_ID
# - TEACHER_EMAIL
# - SHEET_ID
# - GCP_PROJECT_ID
# - GCP_REGION
# - GCP_SERVICE_ACCOUNT_KEY
# - CLOUD_FUNCTION_URL (optional)
```

See [.github/SECRETS.md](.github/SECRETS.md) for detailed instructions.

3. **Enable GitHub Actions**:
   - Go to repository → Actions tab
   - Enable workflows if prompted

### Automated Deployment

After setup, deployments happen automatically:

```bash
# Make changes to Apps Script
nano apps-script/Code.gs

# Commit and push
git add apps-script/Code.gs
git commit -m "feat: update dashboard UI"
git push

# GitHub Actions deploys automatically!
# Monitor at: https://github.com/andycasey/nbd/actions
```

### Manual Trigger

You can also trigger deployments manually:

1. Go to **Actions** tab
2. Select workflow (e.g., "Deploy Apps Script")
3. Click **Run workflow**
4. Select branch and click **Run workflow**

## Verification Checklist

After deployment, verify:

### Apps Script
- [ ] Dashboard loads at web app URL
- [ ] Can create test assignment
- [ ] Invite link generates successfully
- [ ] Test student can access and get notebook

### Cloud Function
- [ ] Function URL is accessible
- [ ] Function logs show no errors
- [ ] Can trigger grading from dashboard

### Database
- [ ] Google Sheet has "Assignments" and "Submissions" tabs
- [ ] Assignment creation adds row to sheet
- [ ] Student access adds row to submissions

### Integration
- [ ] Apps Script can call Cloud Function
- [ ] Grading produces CSV output
- [ ] Email notification sent (if configured)

## Troubleshooting

### Common Issues

#### "Billing not enabled" error
**Solution:**
1. Go to https://console.cloud.google.com/billing
2. Link billing account to project
3. Re-run API enablement

#### Apps Script deployment succeeds but web app shows old code
**Solution:**
1. Go to Apps Script editor
2. Deploy → Manage deployments
3. Edit active deployment
4. Save (creates new version)

#### Cloud Function timeout
**Solution:**
- Increase timeout: `--timeout=540s`
- Increase memory: `--memory=2048MB`
- Check notebook complexity

#### GitHub Actions fails with authentication error
**Solution:**
- Verify secrets are set correctly
- Check JSON format (use `jq` to validate)
- Ensure service account has permissions

### Getting Help

1. **Check logs**:
   ```bash
   # Apps Script logs
   clasp logs

   # Cloud Function logs
   gcloud functions logs read grade-notebooks --region=us-central1

   # GitHub Actions logs
   # Go to Actions tab in repository
   ```

2. **Review documentation**:
   - [Setup Checklist](SETUP-CHECKLIST.md)
   - [Teacher Quickstart](docs/teacher-quickstart.md)
   - [GCP Setup](setup/gcp-setup.md)

3. **File an issue**:
   - https://github.com/andycasey/nbd/issues

## Maintenance

### Updating Code

```bash
# Pull latest changes
git pull origin main

# If using CI/CD, changes deploy automatically
# If manual, re-run deployment scripts
npm run deploy:all
```

### Rotating Credentials

**Every 90 days:**

1. Regenerate service account key:
   ```bash
   gcloud iam service-accounts keys create credentials/service-account-key.json \
     --iam-account=$SA_EMAIL
   ```

2. Update GitHub secret `GCP_SERVICE_ACCOUNT_KEY`

3. Regenerate clasp credentials:
   ```bash
   clasp logout
   clasp login
   ```

4. Update GitHub secret `CLASP_CREDENTIALS`

### Monitoring Costs

Set up billing alerts:

```bash
# View current costs
gcloud billing accounts list
gcloud billing projects describe $PROJECT_ID

# Set up alert (manual in console)
echo "Set budget alert at: https://console.cloud.google.com/billing/budgets"
```

Typical costs:
- Apps Script: $0
- Google Drive: $0
- Cloud Functions: ~$0.50/semester (30 students, 10 assignments)
- Total: **~$0.60/semester**

## Production Best Practices

1. **Use separate projects for dev/staging/prod**:
   ```bash
   nbd-dev-xxxxx
   nbd-staging-xxxxx
   nbd-prod-xxxxx
   ```

2. **Use environment-specific branches**:
   - `main` → production
   - `staging` → staging environment
   - `dev` → development

3. **Tag releases**:
   ```bash
   git tag -a v1.0.0 -m "Production release v1.0.0"
   git push origin v1.0.0
   ```

4. **Monitor production**:
   - Set up error alerting
   - Review logs weekly
   - Monitor costs monthly

5. **Backup data**:
   - Google Sheets auto-saves
   - Export grades after each assignment
   - Keep local copy of notebooks

## Next Steps

After successful deployment:

1. **Create first assignment**: [Teacher Quickstart](docs/teacher-quickstart.md)
2. **Test with students**: Start with small pilot group
3. **Gather feedback**: Iterate on workflow
4. **Scale up**: Roll out to full class

Happy grading! 🎓
