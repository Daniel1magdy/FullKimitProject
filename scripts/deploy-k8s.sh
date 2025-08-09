#!/bin/bash
# scripts/deploy-k8s.sh

set -e

AWS_REGION="eu-west-2"
CLUSTER_NAME="devops-cluster"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "🚀 Deploying applications to Kubernetes..."
echo "Cluster: ${CLUSTER_NAME}"
echo "Region: ${AWS_REGION}"
echo "Registry: ${ECR_REGISTRY}"
echo ""

# Update kubeconfig
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}

# Test cluster connectivity
echo "🔍 Testing cluster connectivity..."
kubectl cluster-info
kubectl get nodes

# Create backup of original files
cp k8s/frontend-deployment.yaml k8s/frontend-deployment.yaml.bak
cp k8s/backend-deployment.yaml k8s/backend-deployment.yaml.bak

# Update image URIs in manifests
echo "📝 Updating Kubernetes manifests..."
sed -i "s|FRONTEND_IMAGE_URI|${ECR_REGISTRY}/devops-frontend:latest|g" k8s/frontend-deployment.yaml
sed -i "s|BACKEND_IMAGE_URI|${ECR_REGISTRY}/devops-backend:latest|g" k8s/backend-deployment.yaml

# Deploy to Kubernetes
echo "📦 Deploying Backend application..."
kubectl apply -f k8s/backend-deployment.yaml

echo "📦 Deploying Frontend application..."
kubectl apply -f k8s/frontend-deployment.yaml

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl rollout status deployment/backend-deployment --timeout=300s
kubectl rollout status deployment/frontend-deployment --timeout=300s

echo ""
echo "✅ Applications deployed successfully!"
echo ""

# Show status
echo "=== DEPLOYMENTS ==="
kubectl get deployments

echo ""
echo "=== SERVICES ==="
kubectl get services

echo ""
echo "=== PODS ==="
kubectl get pods

# Get application URLs
echo ""
echo "=== APPLICATION URLs ==="
echo "Getting LoadBalancer URLs (may take a few minutes)..."

FRONTEND_URL=$(kubectl get service frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -z "$FRONTEND_URL" ]; then
    echo "Frontend LoadBalancer IP is still pending..."
    echo "Check with: kubectl get service frontend-service"
else
    echo "Frontend URL: http://${FRONTEND_URL}"
fi

echo ""
echo "🔍 To check LoadBalancer status later:"
echo "kubectl get services"
echo ""
echo "🔍 To get application logs:"
echo "kubectl logs -l app=frontend"
echo "kubectl logs -l app=backend"

# Restore original files
echo "🧹 Restoring original manifest files..."
mv k8s/frontend-deployment.yaml.bak k8s/frontend-deployment.yaml
mv k8s/backend-deployment.yaml.bak k8s/backend-deployment.yaml

echo ""
echo "✅ Deployment completed successfully!"
