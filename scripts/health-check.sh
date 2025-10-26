#!/bin/bash

# AWX Health Check Script
# This script checks the health of your AWX deployment

echo "=== AWX Health Check ==="
echo "Timestamp: $(date)"
echo ""

# Check if kind cluster exists
echo "1. Checking Kind cluster status..."
if kind get clusters | grep -q "awx-cluster"; then
    echo "✅ Kind cluster 'awx-cluster' exists"
else
    echo "❌ Kind cluster 'awx-cluster' not found"
    exit 1
fi

# Check kubectl context
echo ""
echo "2. Checking kubectl context..."
current_context=$(kubectl config current-context)
if [[ "$current_context" == "kind-awx-cluster" ]]; then
    echo "✅ kubectl context is set correctly: $current_context"
else
    echo "⚠️  kubectl context is: $current_context (expected: kind-awx-cluster)"
fi

# Check cluster connectivity
echo ""
echo "3. Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    echo "✅ Cluster is accessible"
else
    echo "❌ Cannot connect to cluster"
    exit 1
fi

# Check AWX namespace
echo ""
echo "4. Checking AWX namespace..."
if kubectl get namespace awx &> /dev/null; then
    echo "✅ AWX namespace exists"
else
    echo "❌ AWX namespace not found"
    exit 1
fi

# Check AWX operator
echo ""
echo "5. Checking AWX Operator..."
# Check in awx-operator-system first, then awx namespace as fallback
operator_status=""
if kubectl get deployment awx-operator-controller-manager -n awx-operator-system >/dev/null 2>&1; then
    operator_status=$(kubectl get deployment awx-operator-controller-manager -n awx-operator-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    operator_namespace="awx-operator-system"
elif kubectl get deployment awx-operator-controller-manager -n awx >/dev/null 2>&1; then
    operator_status=$(kubectl get deployment awx-operator-controller-manager -n awx -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    operator_namespace="awx"
fi

if [[ "$operator_status" == "1" ]]; then
    echo "✅ AWX Operator is running (in $operator_namespace namespace)"
else
    echo "❌ AWX Operator is not ready"
fi

# Check AWX instance
echo ""
echo "6. Checking AWX instance..."
if kubectl get awx awx -n awx &> /dev/null; then
    echo "✅ AWX instance exists"
    awx_status=$(kubectl get awx awx -n awx -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [[ "$awx_status" == "True" ]]; then
        echo "✅ AWX instance is ready"
    else
        echo "⚠️  AWX instance is not ready yet"
    fi
else
    echo "❌ AWX instance not found"
fi

# Check pods
echo ""
echo "7. Checking AWX pods..."
kubectl get pods -n awx --no-headers 2>/dev/null | while read line; do
    pod_name=$(echo $line | awk '{print $1}')
    pod_status=$(echo $line | awk '{print $3}')
    if [[ "$pod_status" == "Running" ]]; then
        echo "✅ $pod_name: $pod_status"
    else
        echo "⚠️  $pod_name: $pod_status"
    fi
done

# Check services
echo ""
echo "8. Checking services..."
if kubectl get service awx-service -n awx &> /dev/null; then
    echo "✅ AWX service exists"
else
    echo "❌ AWX service not found"
fi

# Check persistent volumes
echo ""
echo "9. Checking persistent volumes..."
pv_count=$(kubectl get pv | grep -c "awx" 2>/dev/null || echo "0")
echo "📊 Found $pv_count AWX-related persistent volumes"

# Check if port-forward is running
echo ""
echo "10. Checking port-forward status..."
if pgrep -f "kubectl port-forward.*awx-service" > /dev/null; then
    echo "✅ Port-forward is active"
    echo "🌐 AWX should be accessible at: http://localhost:9080"
else
    echo "⚠️  Port-forward is not active"
    echo "💡 Run: kubectl port-forward service/awx-service 9080:80 -n awx"
fi

# Test AWX API if port-forward is active
echo ""
echo "11. Testing AWX API..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9080/api/v2/ping/ | grep -q "200"; then
    echo "✅ AWX API is responding"
else
    echo "⚠️  AWX API is not responding (check port-forward)"
fi

echo ""
echo "=== Health Check Complete ==="
echo ""

# Display useful information
echo "📋 Useful Commands:"
echo "   View pods: kubectl get pods -n awx"
echo "   View logs: kubectl logs -f deployment/awx-web -n awx"
echo "   Port forward: kubectl port-forward service/awx-service 9080:80 -n awx"
echo "   Get admin password: kubectl get secret awx-admin-password -o jsonpath=\"{.data.password}\" -n awx | base64 --decode"
