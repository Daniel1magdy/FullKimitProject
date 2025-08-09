#!/bin/bash
# k8s/monitoring/install-monitoring.sh

set -e

echo "🚀 Installing Monitoring Stack (Prometheus + Grafana)"

# Add Helm repositories
echo "📦 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo "🏗️ Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus
echo "📊 Installing Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --values k8s/monitoring/prometheus-values.yaml \
  --wait --timeout=600s

# Install Grafana
echo "📈 Installing Grafana..."
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values k8s/monitoring/grafana-values.yaml \
  --wait --timeout=600s

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-server -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring

# Get service URLs
echo "🌐 Getting service URLs..."
echo ""
echo "=== MONITORING SERVICES ==="
echo "Prometheus URL:"
kubectl get service prometheus-server -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "LoadBalancer IP pending..."

echo ""
echo "Grafana URL:"
kubectl get service grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "LoadBalancer IP pending..."

echo ""
echo "Grafana Login: admin / admin123"
echo ""
echo "✅ Monitoring stack installation completed!"

# Show all monitoring services
echo ""
echo "=== MONITORING PODS ==="
kubectl get pods -n monitoring

echo ""
echo "=== MONITORING SERVICES ==="
kubectl get services -n monitoring
