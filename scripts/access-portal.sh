#!/bin/bash

# Simple AWX Access Script
# This script provides easy access to your AWX portal

echo "🚀 AWX Portal Access Manager"
echo "==========================="
echo

# Check if AWX is running
echo "🔍 Checking AWX status..."
if ! kubectl get pods -n awx | grep -q "awx-web.*Running"; then
    echo "❌ AWX is not running. Please deploy AWX first."
    echo "   Run: ./setup.sh or ./scripts/quick-deploy.sh"
    exit 1
fi

echo "✅ AWX is running!"
echo

# Kill any existing port-forwards on 9080
echo "🧹 Cleaning up existing connections..."
pkill -f "kubectl.*port-forward.*9080" 2>/dev/null || true
sleep 2

# Start new port-forward
echo "🔌 Starting port-forward..."
kubectl port-forward -n awx svc/awx-service 9080:80 >/dev/null 2>&1 &
PF_PID=$!

# Wait for connection
sleep 3

# Test connection
echo "🔍 Testing connection..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9080/ | grep -q "200"; then
    echo "✅ AWX Portal is ready!"
    echo
    echo "🌐 Access Information:"
    echo "   URL: http://localhost:9080"
    echo "   Username: admin"
    echo "   Password: $(kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode)"
    echo
    echo "🌍 Opening in your default browser..."
    open http://localhost:9080
    echo
    echo "💡 To stop the connection, press Ctrl+C or run:"
    echo "   pkill -f 'kubectl.*port-forward.*9080'"
    echo
    echo "⏳ Port-forward is running... (PID: $PF_PID)"
    
    # Keep the script running to maintain port-forward
    wait $PF_PID
else
    echo "❌ Could not connect to AWX portal"
    echo "   Check if AWX pods are ready: kubectl get pods -n awx"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi
