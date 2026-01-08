#!/bin/bash
set -e

# AI Agents Docker Image Build Script
# This script builds and pushes container images for the orchestrator and worker agents

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if project ID is provided
if [ -z "$1" ]; then
  echo -e "${RED}Error: GCP Project ID is required${NC}"
  echo "Usage: ./build.sh <gcp-project-id> [<image-tag>]"
  echo ""
  echo "Example:"
  echo "  ./build.sh my-gcp-project latest"
  echo "  ./build.sh my-gcp-project v1.0.0"
  exit 1
fi

PROJECT_ID=$1
IMAGE_TAG=${2:-latest}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AI Agents Docker Image Builder${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Project ID: ${PROJECT_ID}"
echo "Image Tag:  ${IMAGE_TAG}"
echo ""

# Enable required APIs
echo -e "${YELLOW}Enabling required GCP APIs...${NC}"
gcloud services enable containerregistry.googleapis.com --project=${PROJECT_ID} 2>/dev/null || true
gcloud services enable artifactregistry.googleapis.com --project=${PROJECT_ID} 2>/dev/null || true

# Configure Docker to use gcloud as credential helper
echo -e "${YELLOW}Configuring Docker authentication...${NC}"
gcloud auth configure-docker gcr.io --quiet

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Building Orchestrator Agent${NC}"
echo -e "${GREEN}========================================${NC}"

cd orchestrator
IMAGE_NAME="gcr.io/${PROJECT_ID}/orchestrator-agent:${IMAGE_TAG}"
echo "Image: ${IMAGE_NAME}"
docker build -t ${IMAGE_NAME} .

echo -e "${YELLOW}Pushing orchestrator image to GCR...${NC}"
docker push ${IMAGE_NAME}

echo -e "${GREEN}✓ Orchestrator agent built and pushed successfully${NC}"
cd ..

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Building Worker Agent${NC}"
echo -e "${GREEN}========================================${NC}"

cd worker
IMAGE_NAME="gcr.io/${PROJECT_ID}/worker-agent:${IMAGE_TAG}"
echo "Image: ${IMAGE_NAME}"
docker build -t ${IMAGE_NAME} .

echo -e "${YELLOW}Pushing worker image to GCR...${NC}"
docker push ${IMAGE_NAME}

echo -e "${GREEN}✓ Worker agent built and pushed successfully${NC}"
cd ..

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Images pushed:"
echo "  1. gcr.io/${PROJECT_ID}/orchestrator-agent:${IMAGE_TAG}"
echo "  2. gcr.io/${PROJECT_ID}/worker-agent:${IMAGE_TAG}"
echo ""
echo "Next steps:"
echo "  1. Navigate to tf/scenarios/gke-ai-agents/"
echo "  2. Create terraform.tfvars with your configuration"
echo "  3. Run: terraform init && terraform apply"
echo ""
echo -e "${GREEN}Happy deploying! 🚀${NC}"
