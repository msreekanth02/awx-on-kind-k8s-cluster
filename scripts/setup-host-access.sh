#!/bin/bash

# AWX Host IP Configuration Script
# Configures AWX to be accessible via host IP address

set -e

# Configuration
HOST_IP="192.168.1.243"
CLUSTER_NAME="awx-cluster"

echo "=== AWX Host IP Configuration ==="
echo "Host IP: $HOST_IP"
echo "Cluster: $CLUSTER_NAME"
echo ""

# Function to check if cluster exists
cluster_exists() {
    kind get clusters | grep -q "^${CLUSTER_NAME}$"
}

# Function to recreate cluster with proper host binding
recreate_cluster_with_host_binding() {
    echo "🔧 Recreating Kind cluster with host IP binding..."
    
    # Delete existing cluster if it exists
    if cluster_exists; then
        echo "   Deleting existing cluster..."
        kind delete cluster --name=$CLUSTER_NAME
    fi
    
    # Create updated cluster config
    cat > /tmp/kind-cluster-hostip.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $CLUSTER_NAME
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 9080
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: 443
    hostPort: 9443
    protocol: TCP
    listenAddress: "0.0.0.0"
- role: worker
  extraMounts:
  - hostPath: /tmp/awx-data
    containerPath: /data
- role: worker
  extraMounts:
  - hostPath: /tmp/awx-data
    containerPath: /data
EOF

    # Create the cluster
    echo "   Creating new cluster with host IP binding..."
    kind create cluster --config=/tmp/kind-cluster-hostip.yaml
    
    # Wait for cluster to be ready
    echo "   Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=60s
    
    echo "   ✅ Cluster created successfully!"
    
    # Clean up temp file
    rm /tmp/kind-cluster-hostip.yaml
}

# Function to setup AWX
setup_awx() {
    echo "🚀 Setting up AWX with host IP configuration..."
    
    # Apply all AWX resources
    cd /Users/sreekanthmatturthi/sree/projects/kind-clusters/my-k8s-project/awx-on-kind-k8s-cluster
    
    # Run the quick deploy script
    ./scripts/quick-deploy.sh
}

# Main execution
echo "This will recreate your Kind cluster to enable host IP access."
echo "All existing data will be lost."
read -p "Continue? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    recreate_cluster_with_host_binding
    setup_awx
    
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "AWX will be accessible via:"
    echo "   🏠 Host IP:    http://$HOST_IP:9080"
    echo "   💻 Localhost: http://localhost:9080"
    echo "   📱 Mobile:    http://$HOST_IP:9080"
    echo ""
    echo "Run the following to get access details:"
    echo "   ./scripts/start-host-access.sh"
else
    echo "Operation cancelled."
    exit 1
fi
