#!/bin/bash
# AWX Host IP Access Script
# This script provides multiple ways to access AWX including host IP methods

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="awx"
HOST_IP="192.168.1.243"
HOST_DOMAIN="awx-192-168-1-243.nip.io"
HTTP_PORT="9080"
HTTPS_PORT="9443"

echo -e "${BLUE}===== AWX Complete Access Guide =====${NC}"
echo

# Get AWX credentials
echo -e "${CYAN}🔐 Getting AWX Credentials...${NC}"
ADMIN_USER=$(kubectl get awx -n $NAMESPACE -o jsonpath='{.items[0].spec.admin_user}' 2>/dev/null || echo "admin")
ADMIN_PASSWORD=$(kubectl get secret awx-admin-password -n $NAMESPACE -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode)

if [ -z "$ADMIN_PASSWORD" ]; then
    echo -e "${RED}❌ Could not retrieve admin password${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Username: ${NC}$ADMIN_USER"
echo -e "${GREEN}✓ Password: ${NC}$ADMIN_PASSWORD"
echo

# Test network connectivity
echo -e "${CYAN}🌐 Testing Network Connectivity...${NC}"

# Test 1: Host IP with hostname header
echo -n "Testing host IP with hostname header... "
if curl -s -o /dev/null -w "%{http_code}" -H "Host: $HOST_DOMAIN" http://$HOST_IP:$HTTP_PORT 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ SUCCESS${NC}"
    HOST_IP_HEADER_WORKS=true
else
    echo -e "${RED}✗ FAILED${NC}"
    HOST_IP_HEADER_WORKS=false
fi

# Test 2: Domain name access
echo -n "Testing domain name access... "
if curl -s -o /dev/null -w "%{http_code}" http://$HOST_DOMAIN:$HTTP_PORT 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ SUCCESS${NC}"
    DOMAIN_WORKS=true
else
    echo -e "${RED}✗ FAILED${NC}"
    DOMAIN_WORKS=false
fi

# Test 3: Localhost access
echo -n "Testing localhost access... "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:$HTTP_PORT 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ SUCCESS${NC}"
    LOCALHOST_WORKS=true
else
    echo -e "${RED}✗ FAILED${NC}"
    LOCALHOST_WORKS=false
fi

echo

# Display access methods
echo -e "${BLUE}===== Available Access Methods =====${NC}"
echo

if [ "$LOCALHOST_WORKS" = true ]; then
    echo -e "${GREEN}✅ Method 1: Localhost Access (Recommended for local development)${NC}"
    echo "   URL: http://localhost:$HTTP_PORT"
    echo "   Status: ✅ Working"
    echo "   Use case: Local development and testing"
    echo
fi

if [ "$HOST_IP_HEADER_WORKS" = true ]; then
    echo -e "${GREEN}✅ Method 2: Host IP Access with Header${NC}"
    echo "   URL: http://$HOST_IP:$HTTP_PORT"
    echo "   Header: Host: $HOST_DOMAIN"
    echo "   Status: ✅ Working"
    echo "   Use case: Direct IP access from same network"
    echo "   Example curl: curl -H \"Host: $HOST_DOMAIN\" http://$HOST_IP:$HTTP_PORT"
    echo
fi

if [ "$DOMAIN_WORKS" = true ]; then
    echo -e "${GREEN}✅ Method 3: Domain Name Access (Recommended for network access)${NC}"
    echo "   URL: http://$HOST_DOMAIN:$HTTP_PORT"
    echo "   Status: ✅ Working"
    echo "   Use case: Access from other devices on the network"
    echo "   Note: This uses nip.io DNS service for automatic IP resolution"
    echo
fi

echo -e "${YELLOW}🔧 Method 4: Port Forward (Alternative)${NC}"
echo "   Command: kubectl port-forward -n $NAMESPACE svc/awx-service 8080:80 --address=0.0.0.0"
echo "   URLs: http://localhost:8080 or http://$HOST_IP:8080"
echo "   Status: Available (run command to activate)"
echo "   Use case: Custom port access or troubleshooting"
echo

# Show current ingress configuration
echo -e "${CYAN}🔍 Current Network Configuration:${NC}"
echo "Host IP: $HOST_IP"
echo "AWX Domain: $HOST_DOMAIN"
echo "HTTP Port: $HTTP_PORT"
echo "HTTPS Port: $HTTPS_PORT"
echo

# Display ingress info
kubectl get ingress -n $NAMESPACE -o custom-columns="NAME:.metadata.name,HOSTS:.spec.rules[*].host,ADDRESS:.status.loadBalancer.ingress[*].ip,PORTS:.spec.rules[*].http.paths[*].backend.service.port.number" 2>/dev/null || echo "Ingress information not available"
echo

# Provide browser links
echo -e "${BLUE}===== Quick Access Links =====${NC}"
echo

if [ "$LOCALHOST_WORKS" = true ]; then
    echo -e "${GREEN}🖥️  Local Access:${NC}"
    echo "   http://localhost:$HTTP_PORT"
fi

if [ "$DOMAIN_WORKS" = true ]; then
    echo -e "${GREEN}🌐 Network Access:${NC}"
    echo "   http://$HOST_DOMAIN:$HTTP_PORT"
fi

echo

# Mobile device instructions
echo -e "${CYAN}📱 Mobile Device Access:${NC}"
echo "If you want to access AWX from mobile devices on the same network:"
echo "1. Connect your mobile device to the same WiFi network"
echo "2. Open browser and go to: http://$HOST_DOMAIN:$HTTP_PORT"
echo "3. Login with the credentials shown above"
echo

# Troubleshooting section
echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
echo
if [ "$DOMAIN_WORKS" = false ]; then
    echo -e "${RED}❌ Domain access failed:${NC}"
    echo "   - Check if DNS resolution works: nslookup $HOST_DOMAIN"
    echo "   - Try using host IP with header instead"
fi

if [ "$LOCALHOST_WORKS" = false ]; then
    echo -e "${RED}❌ Localhost access failed:${NC}"
    echo "   - Check if Kind cluster is running: kind get clusters"
    echo "   - Check port mappings: docker port awx-cluster-control-plane"
fi

if [ "$HOST_IP_HEADER_WORKS" = false ]; then
    echo -e "${RED}❌ Host IP access failed:${NC}"
    echo "   - Check network connectivity"
    echo "   - Verify Kind cluster port binding"
fi

echo

# Security note
echo -e "${YELLOW}⚠️  Security Note:${NC}"
echo "This setup exposes AWX on your local network. For production use:"
echo "- Configure HTTPS/TLS"
echo "- Set up proper authentication"
echo "- Use firewalls and access controls"
echo "- Consider VPN for remote access"
echo

echo -e "${GREEN}🎉 AWX is ready for use!${NC}"
echo "Choose your preferred access method above and enjoy using AWX."
