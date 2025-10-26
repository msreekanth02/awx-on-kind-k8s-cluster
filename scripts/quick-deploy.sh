#!/bin/bash

# AWX Quick Deploy Script
# This script automates the entire AWX deployment process
# Use the interactive setup.sh for a better user experience

set -e  # Exit on any error

# Get script directory and set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESOURCES_DIR="$PROJECT_ROOT/resources"

echo "⚠️  NOTE: For interactive deployment with better UX, use: ./setup.sh"
echo ""
echo "=== AWX on Kind - Quick Deploy ==="
echo "This script will deploy AWX on a Kind Kubernetes cluster"
echo ""

# Check port availability first
echo "0. Checking port availability..."
if ! "$SCRIPT_DIR/check-ports.sh" >/dev/null 2>&1; then
    echo "❌ Port conflicts detected. Running detailed port check..."
    "$SCRIPT_DIR/check-ports.sh"
    exit 1
fi
echo "✅ Required ports are available"
echo ""

# Check prerequisites
echo "1. Checking prerequisites..."

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi
echo "✅ Docker is running"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi
echo "✅ kubectl is available"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ kind is not installed"
    exit 1
fi
echo "✅ kind is available"

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed"
    exit 1
fi
echo "✅ helm is available"

echo ""
echo "2. Creating local data directory..."
mkdir -p /tmp/awx-data
echo "✅ Data directory created: /tmp/awx-data"

echo ""
echo "3. Creating Kind cluster..."
if kind get clusters | grep -q "awx-cluster"; then
    echo "⚠️  Cluster 'awx-cluster' already exists. Deleting..."
    kind delete cluster --name=awx-cluster
fi

kind create cluster --config="$RESOURCES_DIR/kind-cluster-config.yaml" --name=awx-cluster

# Create required directories in kind nodes
echo "Creating storage directories in cluster nodes..."
docker exec awx-cluster-worker mkdir -p /data/postgres /data/projects 2>/dev/null || true
docker exec awx-cluster-worker2 mkdir -p /data/postgres /data/projects 2>/dev/null || true
echo "✅ Kind cluster created"

echo ""
echo "4. Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
echo "✅ NGINX Ingress Controller ready"

echo ""
echo "5. Creating AWX namespace and storage..."
kubectl create namespace awx
kubectl apply -f "$RESOURCES_DIR/awx-pv.yaml"
echo "✅ Namespace and storage created"

echo ""
echo "6. Installing AWX Operator..."
kubectl apply -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1

echo "Waiting for AWX Operator to be ready..."
# Check in both possible namespaces
if kubectl get deployment awx-operator-controller-manager -n awx-operator-system >/dev/null 2>&1; then
    kubectl wait --for=condition=available deployment/awx-operator-controller-manager \
      -n awx-operator-system --timeout=300s
    echo "✅ AWX Operator ready (in awx-operator-system namespace)"
elif kubectl get deployment awx-operator-controller-manager -n awx >/dev/null 2>&1; then
    kubectl wait --for=condition=available deployment/awx-operator-controller-manager \
      -n awx --timeout=300s
    echo "✅ AWX Operator ready (in awx namespace)"
else
    echo "❌ AWX Operator not found in any expected namespace"
    exit 1
fi

echo ""
echo "7. Creating PostgreSQL configuration secret..."
kubectl create secret generic awx-postgres-configuration \
  --from-literal=host=awx-postgres \
  --from-literal=port=5432 \
  --from-literal=database=awx \
  --from-literal=username=awx \
  --from-literal=password=awxpass123 \
  --from-literal=type=managed \
  -n awx
echo "✅ PostgreSQL secret created"

echo ""
echo "8. Deploying AWX instance..."
kubectl apply -f "$RESOURCES_DIR/awx-instance.yaml"

echo ""
echo "9. Waiting for AWX deployment to complete..."
echo "This may take 5-10 minutes. Please be patient..."

# Wait for AWX pods to be ready
timeout=600  # 10 minutes
interval=10
elapsed=0

while [ $elapsed -lt $timeout ]; do
    if kubectl get pods -n awx -l app.kubernetes.io/name=awx --no-headers 2>/dev/null | grep -q "Running"; then
        echo "✅ AWX pods are running"
        break
    fi
    echo "⏳ Waiting for AWX pods... ($elapsed/$timeout seconds)"
    sleep $interval
    elapsed=$((elapsed + interval))
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ Timeout waiting for AWX pods to be ready"
    echo "💡 Check status with: kubectl get pods -n awx"
    exit 1
fi

# Wait specifically for the AWX instance to be ready
echo "Waiting for AWX instance to be fully ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx -n awx --timeout=300s
echo "✅ AWX is ready!"

echo ""
echo "10. Getting admin credentials..."
echo "Waiting for admin password secret to be created..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if kubectl get secret awx-admin-password -n awx &> /dev/null; then
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
done

if kubectl get secret awx-admin-password -n awx &> /dev/null; then
    ADMIN_PASSWORD=$(kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode)
    echo "✅ Admin credentials retrieved"
else
    echo "⚠️  Admin password secret not found. AWX may still be initializing."
    ADMIN_PASSWORD="Please run: kubectl get secret awx-admin-password -o jsonpath=\"{.data.password}\" -n awx | base64 --decode"
fi

echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "🎉 AWX has been successfully deployed!"
echo ""
echo "📋 Access Information:"
echo "   URL: http://localhost:9080"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "🚀 To access AWX:"
echo "   1. Run: ./setup.sh (recommended)"
echo "   2. Or manually: kubectl port-forward service/awx-service 9080:80 -n awx"
echo "   3. Open browser to: http://localhost:9080"
echo "   4. Login with admin credentials above"
echo ""
echo "📊 Useful commands:"
echo "   Interactive management: ./setup.sh"
echo "   Health check: ./health-check.sh"
echo "   View pods: kubectl get pods -n awx"
echo "   View logs: kubectl logs -f deployment/awx-web -n awx"
echo "   Backup: ./backup-awx.sh"
echo ""
echo "📖 For troubleshooting, see README.md or run ./setup.sh"
