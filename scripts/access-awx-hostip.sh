#!/bin/bash

# AWX Access Script with Host IP Support
# Provides multiple ways to access AWX

echo "=== AWX Access Options ==="
echo "Timestamp: $(date)"
echo ""

# Get admin password
ADMIN_PASSWORD=$(kubectl get secret awx-admin-password -o jsonpath='{.data.password}' -n awx | base64 --decode)
HOST_IP="192.168.1.243"

echo "🔐 Admin Credentials:"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""

echo "🌐 Access Methods:"
echo ""

echo "1️⃣  Direct Host IP Access (Recommended):"
echo "   URL: http://$HOST_IP:9080"
echo "   HTTPS: https://$HOST_IP:9443"
echo "   ✅ Accessible from any device on your network"
echo ""

echo "2️⃣  Domain Name Access (using nip.io):"
echo "   URL: http://awx-192-168-1-243.nip.io:9080"
echo "   HTTPS: https://awx-192-168-1-243.nip.io:9443"
echo "   ✅ Provides a proper domain name"
echo ""

echo "3️⃣  Localhost Access:"
echo "   URL: http://localhost:9080"
echo "   HTTPS: https://localhost:9443"
echo "   ⚠️  Only accessible from this machine"
echo ""

echo "4️⃣  Port Forward Method (if direct access doesn't work):"
echo "   Command: kubectl port-forward -n awx svc/awx-service 9080:80"
echo "   Then visit: http://localhost:9080"
echo ""

echo "🔧 Troubleshooting:"
echo "   Check ingress: kubectl get ingress -n awx"
echo "   Check pods: kubectl get pods -n awx"
echo "   Check logs: kubectl logs -f deployment/awx-web -n awx"
echo ""

echo "📱 Mobile/Remote Access:"
echo "   Share this URL with team members: http://$HOST_IP:9080"
echo "   Make sure port 9080 is open in your firewall"
echo ""

# Test connectivity
echo "🧪 Testing connectivity..."
if curl -s -o /dev/null -w "%{http_code}" http://$HOST_IP:9080/ | grep -q "200"; then
    echo "   ✅ Host IP access is working!"
else
    echo "   ⚠️  Host IP access may need firewall configuration"
fi

if curl -s -o /dev/null -w "%{http_code}" http://localhost:9080/ | grep -q "200"; then
    echo "   ✅ Localhost access is working!"
else
    echo "   ⚠️  Localhost access is not responding"
fi

echo ""
echo "🚀 Ready to use! Choose your preferred access method above."
