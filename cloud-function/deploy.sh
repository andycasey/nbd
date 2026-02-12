#!/bin/bash

# Deploy nbgrader Cloud Function to Google Cloud
# Usage: ./deploy.sh [PROJECT_ID]

set -e

PROJECT_ID=${1:-"your-gcp-project-id"}
FUNCTION_NAME="grade-notebooks"
REGION="us-central1"
RUNTIME="python39"
MEMORY="1024MB"
TIMEOUT="540s"
ENTRY_POINT="grade_notebooks"

echo "🚀 Deploying Cloud Function to GCP..."
echo "Project: $PROJECT_ID"
echo "Function: $FUNCTION_NAME"
echo "Region: $REGION"

# Set project
gcloud config set project $PROJECT_ID

# Deploy function
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=$RUNTIME \
  --region=$REGION \
  --source=. \
  --entry-point=$ENTRY_POINT \
  --trigger-http \
  --allow-unauthenticated \
  --memory=$MEMORY \
  --timeout=$TIMEOUT \
  --set-env-vars TEACHER_EMAIL=andrew.casey@monash.edu

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Function URL:"
gcloud functions describe $FUNCTION_NAME --region=$REGION --format='value(serviceConfig.uri)'
echo ""
echo "⚠️  IMPORTANT: Copy the Function URL and update it in apps-script/Code.gs"
echo "   Look for: const CLOUD_FUNCTION_URL = \"YOUR_CLOUD_FUNCTION_URL_HERE\";"
