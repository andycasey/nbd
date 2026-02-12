#!/bin/bash

# Display GitHub Secrets Configuration
# Use this to get values for setting up GitHub repository secrets

echo "════════════════════════════════════════════════════════"
echo "  GitHub Secrets Configuration for NBD"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Copy these values to GitHub Settings → Secrets → Actions"
echo "Repository: https://github.com/andycasey/nbd/settings/secrets/actions"
echo ""
echo "════════════════════════════════════════════════════════"

# Load .env if exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo ""
echo "📧 TEACHER_EMAIL"
echo "────────────────────────────────────────────────────────"
if [ -n "$TEACHER_EMAIL" ]; then
    echo "$TEACHER_EMAIL"
else
    echo "❌ Not set in .env"
fi

echo ""
echo "📊 SHEET_ID"
echo "────────────────────────────────────────────────────────"
if [ -n "$SHEET_ID" ]; then
    echo "$SHEET_ID"
    echo "View: https://docs.google.com/spreadsheets/d/$SHEET_ID"
else
    echo "❌ Not set. Run: npm run create:sheet"
fi

echo ""
echo "📱 APPS_SCRIPT_ID"
echo "────────────────────────────────────────────────────────"
if [ -f apps-script/.clasp.json ]; then
    SCRIPT_ID=$(cat apps-script/.clasp.json | grep scriptId | cut -d'"' -f4)
    echo "$SCRIPT_ID"
    echo "Edit: https://script.google.com/d/$SCRIPT_ID/edit"
else
    echo "❌ Not deployed yet. Run: npm run deploy:apps-script"
fi

echo ""
echo "🔐 CLASP_CREDENTIALS"
echo "────────────────────────────────────────────────────────"
if [ -f ~/.clasprc.json ]; then
    echo "Found at: ~/.clasprc.json"
    echo ""
    echo "Copy this entire JSON:"
    echo "────────────────────────────────────────────────────────"
    cat ~/.clasprc.json
    echo ""
    echo "────────────────────────────────────────────────────────"
else
    echo "❌ Not logged in. Run: clasp login"
fi

echo ""
echo "☁️  GCP_PROJECT_ID"
echo "────────────────────────────────────────────────────────"
if [ -n "$GCP_PROJECT_ID" ]; then
    echo "$GCP_PROJECT_ID"
else
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$CURRENT_PROJECT" ]; then
        echo "$CURRENT_PROJECT (from gcloud)"
    else
        echo "❌ Not set. Run: npm run setup:gcp"
    fi
fi

echo ""
echo "🌍 GCP_REGION"
echo "────────────────────────────────────────────────────────"
if [ -n "$GCP_REGION" ]; then
    echo "$GCP_REGION"
else
    echo "us-central1 (default)"
fi

echo ""
echo "🔑 GCP_SERVICE_ACCOUNT_KEY"
echo "────────────────────────────────────────────────────────"
if [ -f credentials/service-account-key.json ]; then
    echo "Found at: credentials/service-account-key.json"
    echo ""
    echo "Copy this entire JSON:"
    echo "────────────────────────────────────────────────────────"
    cat credentials/service-account-key.json
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo ""
    echo "⚠️  WARNING: This is sensitive! Never commit to Git."
else
    echo "❌ Not created. Run: npm run setup:gcp"
fi

echo ""
echo "🔗 CLOUD_FUNCTION_URL (optional)"
echo "────────────────────────────────────────────────────────"
if [ -n "$CLOUD_FUNCTION_URL" ]; then
    echo "$CLOUD_FUNCTION_URL"
else
    if [ -n "$GCP_PROJECT_ID" ] && [ -n "$GCP_REGION" ]; then
        # Try to get URL from deployed function
        FUNCTION_URL=$(gcloud functions describe grade-notebooks \
            --region="${GCP_REGION:-us-central1}" \
            --gen2 \
            --format='value(serviceConfig.uri)' 2>/dev/null)

        if [ -n "$FUNCTION_URL" ]; then
            echo "$FUNCTION_URL (from deployed function)"
        else
            echo "⚠️  Not deployed yet. Will be set after first Cloud Function deployment."
        fi
    else
        echo "⚠️  Not deployed yet. Run: npm run deploy:cloud-function"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Next Steps"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. Go to: https://github.com/andycasey/nbd/settings/secrets/actions"
echo "2. Click 'New repository secret' for each secret above"
echo "3. Copy the values shown above"
echo "4. Push changes to trigger automated deployment"
echo ""
echo "For help: see .github/SECRETS.md"
echo ""
