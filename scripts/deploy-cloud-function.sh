#!/bin/bash

# Deploy Cloud Function for automated grading

set -e

echo "☁️  Deploying Cloud Function"
echo "============================"

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ No .env file found. Run 'cp .env.template .env' and configure it first."
    exit 1
fi

PROJECT_ID=${GCP_PROJECT_ID}
REGION=${GCP_REGION:-us-central1}
FUNCTION_NAME="grade-notebooks"

if [ -z "$PROJECT_ID" ]; then
    echo "❌ GCP_PROJECT_ID not set in .env"
    exit 1
fi

# Set project
gcloud config set project $PROJECT_ID

# Navigate to cloud-function directory
cd cloud-function

echo "Deploying to project: $PROJECT_ID"
echo "Region: $REGION"
echo "Function: $FUNCTION_NAME"
echo ""

# Deploy function
gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime=python311 \
    --region=$REGION \
    --source=. \
    --entry-point=grade_notebooks \
    --trigger-http \
    --allow-unauthenticated \
    --memory=1024MB \
    --timeout=540s \
    --set-env-vars TEACHER_EMAIL=$TEACHER_EMAIL

echo ""
echo "✅ Cloud Function deployed successfully!"
echo ""

# Get function URL
FUNCTION_URL=$(gcloud functions describe $FUNCTION_NAME \
    --region=$REGION \
    --gen2 \
    --format='value(serviceConfig.uri)' 2>/dev/null)

if [ -n "$FUNCTION_URL" ]; then
    echo "Function URL: $FUNCTION_URL"
    echo ""

    # Update .env file
    cd ..
    if grep -q "^CLOUD_FUNCTION_URL=" .env; then
        sed -i.bak "s|^CLOUD_FUNCTION_URL=.*|CLOUD_FUNCTION_URL=$FUNCTION_URL|" .env
    else
        echo "CLOUD_FUNCTION_URL=$FUNCTION_URL" >> .env
    fi
    rm -f .env.bak

    echo "✅ Updated .env with function URL"
    echo ""
    echo "⚠️  Important: Re-deploy Apps Script to use the new function URL"
    echo "Run: npm run deploy:apps-script"
else
    echo "⚠️  Couldn't retrieve function URL automatically"
    echo "Get it with:"
    echo "gcloud functions describe $FUNCTION_NAME --region=$REGION --gen2 --format='value(serviceConfig.uri)'"
fi

echo ""
