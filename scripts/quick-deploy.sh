#!/bin/bash

# AWX on Kind Kubernetes Cluster - Quick Deploy
# Enterprise-grade deployment with consistent configuration

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration constants - ensures consistency across deployments
CLUSTER_NAME="awx-cluster"
AWX_NAMESPACE="awx"
SERVICE_PORT=8082
AWX_INSTANCE_NAME="awx"
DB_NAME="awx"
ADMIN_PASSWORD="password"

print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "error")   echo -e "${RED}❌ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "info")    echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              AWX on Kind Kubernetes - Quick Deploy            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

get_current_ip() {
    ipconfig getifaddr en0 2>/dev/null || hostname -I | cut -d' ' -f1
}

check_dependencies() {
    local missing_deps=()
    
    if ! command -v kind &> /dev/null; then
        missing_deps+=("kind")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_deps+=("kubectl")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "error" "Missing dependencies: ${missing_deps[*]}"
        echo -e "${YELLOW}Please install the missing dependencies:${NC}"
        echo -e "  - kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        echo -e "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo -e "  - docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

cleanup_existing() {
    if kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        print_status "warning" "Existing cluster found - cleaning up"
        pkill -f "kubectl.*port-forward.*$SERVICE_PORT" 2>/dev/null || true
        kind delete cluster --name=$CLUSTER_NAME
        print_status "success" "Cleanup completed"
    fi
}

create_cluster() {
    print_status "info" "Creating Kind cluster with consistent configuration..."
    
    # Create cluster config for consistent deployments
    cat > /tmp/kind-cluster-config.yaml << EOF
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
    hostPort: $SERVICE_PORT
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
- role: worker
- role: worker
EOF

    if kind create cluster --config=/tmp/kind-cluster-config.yaml --wait=300s; then
        print_status "success" "Kind cluster created successfully"
        rm -f /tmp/kind-cluster-config.yaml
    else
        print_status "error" "Failed to create Kind cluster"
        exit 1
    fi
}

deploy_awx_operator() {
    print_status "info" "Installing AWX Operator..."
    
    kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/devel/deploy/awx-operator.yaml
    
    print_status "info" "Waiting for AWX Operator to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx-operator-system
    
    if [ $? -eq 0 ]; then
        print_status "success" "AWX Operator deployed successfully"
    else
        print_status "error" "AWX Operator deployment failed"
        exit 1
    fi
}

create_awx_instance() {
    print_status "info" "Creating AWX instance with consistent configuration..."
    
    # Create AWX namespace
    kubectl create namespace $AWX_NAMESPACE || true
    
    # Create AWX instance with fixed naming for consistency
    cat > /tmp/awx-instance.yaml << EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: $AWX_INSTANCE_NAME
  namespace: $AWX_NAMESPACE
spec:
  service_type: nodeport
  admin_user: admin
  admin_password_secret_key: password
  postgres_configuration_secret: awx-postgres-configuration
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-admin-password
  namespace: $AWX_NAMESPACE
stringData:
  password: $ADMIN_PASSWORD
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: $AWX_NAMESPACE
stringData:
  host: awx-postgres-15
  port: "5432"
  database: $DB_NAME
  username: awx
  password: awx
  type: managed
EOF

    kubectl apply -f /tmp/awx-instance.yaml
    rm -f /tmp/awx-instance.yaml
    
    print_status "success" "AWX instance configuration applied"
}

wait_for_deployment() {
    print_status "info" "Waiting for AWX deployment to complete..."
    
    local timeout=600  # 10 minutes
    local elapsed=0
    local interval=15
    
    while [ $elapsed -lt $timeout ]; do
        # Check if both web and task pods are running
        local web_ready=$(kubectl get pods -n $AWX_NAMESPACE | grep -E "awx-web.*Running" | wc -l)
        local task_ready=$(kubectl get pods -n $AWX_NAMESPACE | grep -E "awx-task.*Running" | wc -l)
        local postgres_ready=$(kubectl get pods -n $AWX_NAMESPACE | grep -E "awx-postgres-15-0.*Running" | wc -l)
        
        if [ "$web_ready" -gt 0 ] && [ "$task_ready" -gt 0 ] && [ "$postgres_ready" -gt 0 ]; then
            print_status "success" "AWX deployment completed successfully"
            return 0
        fi
        
        echo -e "${YELLOW}⏳ Waiting for AWX pods to be ready... (${elapsed}s/${timeout}s)${NC}"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    print_status "error" "AWX deployment timed out"
    echo -e "${YELLOW}Current pod status:${NC}"
    kubectl get pods -n $AWX_NAMESPACE
    exit 1
}

setup_network_access() {
    print_status "info" "Setting up network access..."
    
    # Kill any existing port forwarding
    pkill -f "kubectl.*port-forward.*$SERVICE_PORT" 2>/dev/null || true
    sleep 2
    
    # Start port forwarding in background with network access
    kubectl port-forward svc/awx-service -n $AWX_NAMESPACE $SERVICE_PORT:80 --address 0.0.0.0 &
    
    # Give it time to start
    sleep 5
    
    # Test local connectivity
    local test_result=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT/ 2>/dev/null)
    if [ "$test_result" = "200" ]; then
        print_status "success" "Network access configured successfully"
    else
        print_status "warning" "Port forwarding started but portal not yet ready"
    fi
}

display_success() {
    local current_ip=$(get_current_ip)
    
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 DEPLOYMENT COMPLETE! 🎉                ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}🌐 AWX Portal Access:${NC}"
    echo -e "   ${BLUE}Local:${NC}    http://localhost:$SERVICE_PORT"
    if [ ! -z "$current_ip" ]; then
        echo -e "   ${BLUE}Host IP:${NC}  http://$current_ip:$SERVICE_PORT"
        echo -e "   ${BLUE}nip.io:${NC}   http://awx-${current_ip//./-}.nip.io:$SERVICE_PORT"
    fi
    echo
    echo -e "${YELLOW}🔑 Login Credentials:${NC}"
    echo -e "   ${BLUE}Username:${NC} admin"
    echo -e "   ${BLUE}Password:${NC} $ADMIN_PASSWORD"
    echo
    echo -e "${YELLOW}🛠️  Management:${NC}"
    echo -e "   ${BLUE}Control Center:${NC} ./awx-manager.sh"
    echo -e "   ${BLUE}Status Check:${NC}  ./final-status.sh"
    echo -e "   ${BLUE}Create Backup:${NC}  ./scripts/backup-awx-data.sh"
    echo
    echo -e "${GREEN}🏆 Your enterprise-grade AWX cluster is ready for automation!${NC}"
    echo
}

main() {
    print_header
    
    print_status "info" "Starting AWX deployment with consistent configuration"
    echo
    
    # Check dependencies
    check_dependencies
    
    # Clean up any existing cluster
    cleanup_existing
    
    # Create cluster
    create_cluster
    
    # Deploy AWX Operator
    deploy_awx_operator
    
    # Create AWX instance
    create_awx_instance
    
    # Wait for deployment
    wait_for_deployment
    
    # Setup network access
    setup_network_access
    
    # Display success information
    display_success
}

# Run main function
main "$@"
