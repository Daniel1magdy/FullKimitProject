#!/bin/bash
# scripts/build-images.sh

set -e

AWS_REGION="eu-west-2"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FRONTEND_REPO="${ECR_REGISTRY}/devops-frontend"
BACKEND_REPO="${ECR_REGISTRY}/devops-backend"
IMAGE_TAG="manual-$(date +%Y%m%d-%H%M%S)"

echo "🐳 Building and pushing Docker images manually..."
echo "Registry: ${ECR_REGISTRY}"
echo "Frontend Repo: ${FRONTEND_REPO}"
echo "Backend Repo: ${BACKEND_REPO}"
echo "Image Tag: ${IMAGE_TAG}"
echo ""

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Build and push frontend
echo "🏗️ Building Frontend Docker image..."
docker build -t ${FRONTEND_REPO}:${IMAGE_TAG} -t ${FRONTEND_REPO}:latest ./frontend/
echo "📤 Pushing Frontend image to ECR..."
docker push ${FRONTEND_REPO}:${IMAGE_TAG}
docker push ${FRONTEND_REPO}:latest

# Build and push backend
echo "🏗️ Building Backend Docker image..."
docker build -t ${BACKEND_REPO}:${IMAGE_TAG} -t ${BACKEND_REPO}:latest ./backend/
echo "📤 Pushing Backend image to ECR..."
docker push ${BACKEND_REPO}:${IMAGE_TAG}
docker push ${BACKEND_REPO}:latest

echo ""
echo "✅ Images built and pushed successfully!"
echo "Frontend: ${FRONTEND_REPO}:${IMAGE_TAG}"
echo "Backend: ${BACKEND_REPO}:${IMAGE_TAG}"
echo ""
echo "You can now deploy these images using:"
echo "./scripts/deploy-k8s.sh"
