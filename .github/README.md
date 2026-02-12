# GitHub Actions CI/CD

This directory contains automated deployment workflows for the NBD Grading System.

## Workflows

### 1. Deploy Apps Script (`deploy-apps-script.yml`)
- **Trigger:** Push to `main` branch when `apps-script/` changes
- **Manual:** Can be triggered via GitHub Actions UI
- **What it does:**
  - Updates configuration with secrets
  - Pushes code to Apps Script
  - Creates new version
  - Deploys to production

### 2. Deploy Cloud Function (`deploy-cloud-function.yml`)
- **Trigger:** Push to `main` branch when `cloud-function/` changes
- **Manual:** Can be triggered via GitHub Actions UI
- **What it does:**
  - Authenticates with GCP
  - Deploys Cloud Function
  - Outputs function URL

### 3. Test (`test.yml`)
- **Trigger:** Pull requests and pushes to `main`
- **What it does:**
  - Lints Python code
  - Validates Apps Script files
  - Validates notebook formats

## Setup

See [SECRETS.md](./SECRETS.md) for complete instructions on configuring GitHub secrets.

### Quick Start

1. **Configure secrets** (Settings → Secrets → Actions):
   ```
   CLASP_CREDENTIALS
   APPS_SCRIPT_ID
   TEACHER_EMAIL
   SHEET_ID
   GCP_PROJECT_ID
   GCP_REGION
   GCP_SERVICE_ACCOUNT_KEY
   CLOUD_FUNCTION_URL (optional)
   ```

2. **Enable workflows**:
   - Go to Actions tab
   - Enable workflows if prompted

3. **Test deployment**:
   ```bash
   # Make a small change to trigger workflow
   echo "# Updated" >> apps-script/README.md
   git add apps-script/README.md
   git commit -m "Test: trigger Apps Script deployment"
   git push
   ```

4. **Monitor deployment**:
   - Go to Actions tab
   - Watch workflow execution
   - Check logs for any errors

## Manual Deployment

You can also manually trigger deployments:

1. Go to **Actions** tab
2. Select workflow (Deploy Apps Script or Deploy Cloud Function)
3. Click **Run workflow**
4. Select branch and click **Run workflow**

## Workflow Status Badges

Add these to your README.md:

```markdown
![Deploy Apps Script](https://github.com/andycasey/nbd/actions/workflows/deploy-apps-script.yml/badge.svg)
![Deploy Cloud Function](https://github.com/andycasey/nbd/actions/workflows/deploy-cloud-function.yml/badge.svg)
![Test](https://github.com/andycasey/nbd/actions/workflows/test.yml/badge.svg)
```

## Troubleshooting

### Deployment fails with authentication error
- Check that secrets are configured correctly
- Verify `CLASP_CREDENTIALS` is valid JSON
- Ensure `GCP_SERVICE_ACCOUNT_KEY` has required permissions

### Apps Script deployment succeeds but changes not visible
- Apps Script may need manual redeployment for web app
- Go to Apps Script editor → Deploy → Manage deployments
- Edit deployment and save

### Cloud Function deployment succeeds but Apps Script can't call it
- Check that `CLOUD_FUNCTION_URL` secret is updated
- Re-deploy Apps Script to pick up new URL
- Verify Cloud Function allows unauthenticated calls

## Development Workflow

Recommended workflow for development:

1. **Create feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes and test locally**:
   ```bash
   # Test Apps Script
   cd apps-script && clasp push && clasp deploy

   # Test Cloud Function
   cd cloud-function && gcloud functions deploy ...
   ```

3. **Create pull request**:
   ```bash
   git push -u origin feature/my-feature
   ```
   - CI tests run automatically
   - Review deployment preview

4. **Merge to main**:
   - Deployments run automatically
   - Monitor in Actions tab

## Cost Monitoring

GitHub Actions usage:
- Free tier: 2,000 minutes/month for public repos
- Typical deployment: ~2-3 minutes
- ~60 deployments per month before hitting limits

To optimize:
- Use `paths` filters to only run on relevant changes
- Combine related changes in single commit
- Use manual triggers for testing

## Security

- Secrets are encrypted at rest
- Secrets are not exposed in logs
- Service accounts use least-privilege access
- Credentials are rotated every 90 days

## Support

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [clasp Documentation](https://github.com/google/clasp)
- [gcloud CLI Documentation](https://cloud.google.com/sdk/gcloud)
