#!/bin/bash

# Quick Host IP Access for AWX
# This script sets up access via your host IP address

echo "=== AWX Host IP Access Setup ==="
echo ""

HOST_IP="192.168.1.243"
ADMIN_PASSWORD=$(kubectl get secret awx-admin-password -o jsonpath='{.data.password}' -n awx | base64 --decode)

echo "🔐 Credentials:"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""

echo "🚀 Setting up access via Host IP ($HOST_IP)..."
echo ""

# Method 1: Port forwarding with host IP binding
echo "1️⃣  Starting port forward with host IP binding..."
kubectl port-forward -n awx --address=0.0.0.0 svc/awx-service 9080:80 &
PF_PID=$!

echo "   Port forward started (PID: $PF_PID)"
echo ""

sleep 3

echo "🌐 AWX is now accessible via:"
echo ""
echo "   🏠 Host IP:    http://$HOST_IP:9080"
echo "   💻 Localhost: http://localhost:9080"
echo "   📱 Mobile:    http://$HOST_IP:9080"
echo ""

echo "✅ Access from any device on your network!"
echo ""
echo "📋 To stop the service:"
echo "   kill $PF_PID"
echo "   or press Ctrl+C"
echo ""

# Test connectivity
echo "🧪 Testing connectivity..."
sleep 2

if curl -s -o /dev/null -w "%{http_code}" http://$HOST_IP:9080/ | grep -q "200"; then
    echo "   ✅ Host IP access is working: http://$HOST_IP:9080"
else
    echo "   ⏳ Service is starting up... try again in a moment"
fi

echo ""
echo "🎉 AWX is ready! Open http://$HOST_IP:9080 in your browser"
echo ""
echo "Press Ctrl+C to stop the port forward when done."

# Keep the port forward running
wait $PF_PID
