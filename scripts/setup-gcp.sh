#!/bin/bash

# NBD GCP Setup Script
# This script automates the Google Cloud Platform setup

set -e

echo "🚀 NBD Google Cloud Platform Setup"
echo "===================================="
echo ""

# Load environment variables if .env exists
if [ -f .env ]; then
    echo "Loading configuration from .env..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  No .env file found. Using defaults from .env.template"
    export $(cat .env.template | grep -v '^#' | xargs)
fi

PROJECT_ID=${GCP_PROJECT_ID}
BILLING_ACCOUNT=${GCP_BILLING_ACCOUNT}
REGION=${GCP_REGION:-us-central1}

echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Step 1: Check if project exists
echo "Step 1: Checking project status..."
if gcloud projects describe $PROJECT_ID &>/dev/null; then
    echo "✓ Project $PROJECT_ID exists"
else
    echo "Creating project $PROJECT_ID..."
    gcloud projects create $PROJECT_ID --name="Notebook Grading System"
    echo "✓ Project created"
fi

# Step 2: Set active project
echo ""
echo "Step 2: Setting active project..."
gcloud config set project $PROJECT_ID
echo "✓ Active project set to $PROJECT_ID"

# Step 3: Link billing
echo ""
echo "Step 3: Checking billing status..."
BILLING_STATUS=$(gcloud billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null || echo "false")

if [ "$BILLING_STATUS" = "true" ]; then
    echo "✓ Billing already enabled"
else
    echo "⚠️  Billing not enabled. Attempting to link billing account..."

    if [ -z "$BILLING_ACCOUNT" ]; then
        echo "❌ No billing account found in .env"
        echo ""
        echo "Available billing accounts:"
        gcloud billing accounts list
        echo ""
        echo "To enable billing:"
        echo "1. Go to: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
        echo "2. Link a billing account"
        echo "3. Re-run this script"
        exit 1
    else
        gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT || {
            echo ""
            echo "❌ Failed to link billing automatically"
            echo "Please enable billing manually:"
            echo "https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
            exit 1
        }
        echo "✓ Billing account linked"
    fi
fi

# Step 4: Enable APIs
echo ""
echo "Step 4: Enabling required APIs..."
gcloud services enable \
    drive.googleapis.com \
    gmail.googleapis.com \
    cloudfunctions.googleapis.com \
    cloudbuild.googleapis.com \
    sheets.googleapis.com \
    cloudresourcemanager.googleapis.com \
    artifactregistry.googleapis.com \
    run.googleapis.com \
    --project=$PROJECT_ID

echo "✓ APIs enabled"

# Step 5: Create service account
echo ""
echo "Step 5: Creating service account..."
SA_NAME="nbgrader-function"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID &>/dev/null; then
    echo "✓ Service account already exists"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="NBGrader Cloud Function" \
        --description="Service account for automated notebook grading" \
        --project=$PROJECT_ID
    echo "✓ Service account created"
fi

# Step 6: Grant permissions
echo ""
echo "Step 6: Granting service account permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/cloudfunctions.developer" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/iam.serviceAccountUser" \
    --quiet

echo "✓ Permissions granted"

# Step 7: Create service account key
echo ""
echo "Step 7: Creating service account key..."
KEY_FILE="credentials/service-account-key.json"
mkdir -p credentials

if [ -f "$KEY_FILE" ]; then
    echo "⚠️  Service account key already exists at $KEY_FILE"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping key creation"
    else
        gcloud iam service-accounts keys create $KEY_FILE \
            --iam-account=$SA_EMAIL \
            --project=$PROJECT_ID
        echo "✓ Service account key created at $KEY_FILE"
    fi
else
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SA_EMAIL \
        --project=$PROJECT_ID
    echo "✓ Service account key created at $KEY_FILE"
fi

echo ""
echo "===================================="
echo "✅ GCP Setup Complete!"
echo "===================================="
echo ""
echo "Next steps:"
echo "1. Create Google Sheet for database"
echo "2. Update .env file with SHEET_ID"
echo "3. Deploy Apps Script: npm run deploy:apps-script"
echo "4. Deploy Cloud Function: npm run deploy:cloud-function"
echo ""
echo "Project details:"
echo "  Project ID: $PROJECT_ID"
echo "  Service Account: $SA_EMAIL"
echo "  Key file: $KEY_FILE"
echo ""
