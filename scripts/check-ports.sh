#!/bin/bash

# Port Check Script
# This script checks if the required ports are available before starting deployment

echo "=== Port Availability Check ==="
echo ""

# Function to check if a port is in use
check_port() {
    local port=$1
    local description=$2
    
    if lsof -i :$port >/dev/null 2>&1; then
        echo "❌ Port $port is in use ($description)"
        echo "   Process using port $port:"
        lsof -i :$port | head -2
        return 1
    else
        echo "✅ Port $port is available ($description)"
        return 0
    fi
}

# Check required ports
ports_available=true

echo "Checking ports required for AWX deployment..."
echo ""

# Check port 9080 (AWX web interface)
if ! check_port 9080 "AWX Web Interface"; then
    ports_available=false
fi

# Check port 9443 (AWX HTTPS - optional)
if ! check_port 9443 "AWX HTTPS - optional"; then
    ports_available=false
fi

# Check port 5432 (PostgreSQL port-forward - optional)
if ! check_port 5432 "PostgreSQL port-forward - optional"; then
    echo "⚠️  Port 5432 is in use (PostgreSQL port-forward - optional)"
    echo "   This won't prevent AWX deployment but database port-forwarding may conflict"
fi

echo ""

if $ports_available; then
    echo "🎉 All required ports are available!"
    echo "✅ You can proceed with AWX deployment"
    echo ""
    echo "💡 To deploy AWX, run: ./quick-deploy.sh"
    exit 0
else
    echo "❌ Some required ports are in use!"
    echo ""
    echo "🔧 Solutions:"
    echo "   1. Stop processes using the conflicting ports"
    echo "   2. Change the port configuration in kind-cluster-config.yaml"
    echo "   3. Use different ports for port-forwarding"
    echo ""
    echo "📝 Current configuration uses:"
    echo "   - Port 9080 for AWX web interface"
    echo "   - Port 9443 for AWX HTTPS (optional)"
    echo ""
    exit 1
fi
