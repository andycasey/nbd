#!/bin/bash

# Deploy Apps Script using clasp

set -e

echo "📱 Deploying Apps Script"
echo "========================"

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ No .env file found. Run 'cp .env.template .env' and configure it first."
    exit 1
fi

# Check required vars
if [ -z "$TEACHER_EMAIL" ]; then
    echo "❌ TEACHER_EMAIL not set in .env"
    exit 1
fi

if [ -z "$SHEET_ID" ]; then
    echo "❌ SHEET_ID not set in .env. Run 'npm run create:sheet' first."
    exit 1
fi

# Check if clasp is logged in
if [ ! -f ~/.clasprc.json ]; then
    echo "Logging in to clasp..."
    clasp login
fi

# Navigate to apps-script directory
cd apps-script

# Check if .clasp.json exists
if [ -f .clasp.json ]; then
    echo "✓ Found existing Apps Script project"
    SCRIPT_ID=$(cat .clasp.json | grep scriptId | cut -d'"' -f4)
else
    echo "Creating new Apps Script project..."
    clasp create --type webapp --title "NBD Teacher Dashboard" --rootDir .
    SCRIPT_ID=$(cat .clasp.json | grep scriptId | cut -d'"' -f4)
    echo "✓ Created script: $SCRIPT_ID"
fi

# Update Code.gs with environment variables
echo "Updating configuration..."
sed -i.bak "s/const TEACHER_EMAIL = \".*\";/const TEACHER_EMAIL = \"$TEACHER_EMAIL\";/" Code.gs
sed -i.bak "s/const ASSIGNMENTS_SHEET_ID = \".*\";/const ASSIGNMENTS_SHEET_ID = \"$SHEET_ID\";/" Code.gs

# Add Cloud Function URL if available
if [ -n "$CLOUD_FUNCTION_URL" ]; then
    sed -i.bak "s|const CLOUD_FUNCTION_URL = \".*\";|const CLOUD_FUNCTION_URL = \"$CLOUD_FUNCTION_URL\";|" Code.gs
fi

rm -f Code.gs.bak

# Push code
echo "Pushing code to Apps Script..."
clasp push --force

# Deploy
echo "Creating deployment..."
if [ -z "$WEB_APP_URL" ]; then
    # First deployment
    DEPLOYMENT_ID=$(clasp deploy --description "Automated deployment $(date +%Y-%m-%d)" 2>&1 | grep "Created version" | awk '{print $3}' | tr -d '.')

    # Get web app URL
    echo "Getting web app URL..."
    clasp deploy --deploymentId $DEPLOYMENT_ID 2>&1 | grep -o 'https://script.google.com[^[:space:]]*' || {
        echo ""
        echo "⚠️  Couldn't get web app URL automatically."
        echo "Please manually deploy as web app:"
        echo "1. Open: https://script.google.com/d/$SCRIPT_ID/edit"
        echo "2. Click Deploy → New deployment"
        echo "3. Type: Web app"
        echo "4. Execute as: Me"
        echo "5. Who has access: Anyone"
        echo "6. Copy the web app URL to .env as WEB_APP_URL"
    }
else
    # Redeploy to existing deployment
    clasp deploy --description "Automated deployment $(date +%Y-%m-%d)"
fi

cd ..

# Update .env with script ID
if [ -f .env ]; then
    if grep -q "^SCRIPT_ID=" .env; then
        sed -i.bak "s|^SCRIPT_ID=.*|SCRIPT_ID=$SCRIPT_ID|" .env
    else
        echo "SCRIPT_ID=$SCRIPT_ID" >> .env
    fi
    rm -f .env.bak
fi

echo ""
echo "✅ Apps Script deployed!"
echo "Script ID: $SCRIPT_ID"
echo "Edit: https://script.google.com/d/$SCRIPT_ID/edit"
echo ""
echo "⚠️  Manual step required:"
echo "1. Go to the Apps Script editor"
echo "2. Deploy → New deployment (or Manage deployments → Edit)"
echo "3. Type: Web app"
echo "4. Execute as: Me"
echo "5. Who has access: Anyone"
echo "6. Copy the web app URL and add to .env as WEB_APP_URL"
echo ""
