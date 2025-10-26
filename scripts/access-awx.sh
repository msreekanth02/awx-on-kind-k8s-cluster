#!/bin/bash

# AWX Access Script
# This script helps you access your AWX deployment

echo "=== AWX Access Helper ==="
echo ""

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to cluster. Is the Kind cluster running?"
    exit 1
fi

# Check if AWX is deployed
if ! kubectl get awx awx -n awx &> /dev/null; then
    echo "❌ AWX instance not found. Have you deployed AWX?"
    exit 1
fi

# Check if AWX is ready
awx_ready=$(kubectl get awx awx -n awx -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [[ "$awx_ready" != "True" ]]; then
    echo "⚠️  AWX is not ready yet. Current status:"
    kubectl get pods -n awx
    echo ""
    echo "💡 Wait for all pods to be Running, then try again."
    exit 1
fi

echo "✅ AWX is ready!"
echo ""

# Get admin password
echo "📋 Getting admin credentials..."
if kubectl get secret awx-admin-password -n awx &> /dev/null; then
    ADMIN_PASSWORD=$(kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode)
    echo "✅ Admin password retrieved"
else
    echo "❌ Admin password secret not found"
    exit 1
fi

echo ""
echo "🔐 Login Credentials:"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""

# Check if port-forward is already running
if pgrep -f "kubectl port-forward.*awx-service" > /dev/null; then
    echo "✅ Port-forward is already running"
    echo "🌐 AWX is accessible at: http://localhost:9080"
else
    echo "🚀 Starting port-forward..."
    echo "This will keep running until you press Ctrl+C"
    echo ""
    echo "🌐 AWX will be accessible at: http://localhost:9080"
    echo "🔐 Username: admin"
    echo "🔐 Password: $ADMIN_PASSWORD"
    echo ""
    echo "Press Ctrl+C to stop port-forwarding"
    echo "----------------------------------------"
    
    # Start port-forwarding (this will block)
    kubectl port-forward service/awx-service 9080:80 -n awx
fi
