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
    
    # Use the latest stable release tag
    local AWX_OPERATOR_VERSION="2.19.1"
    
    # Create temporary directory for kustomization
    local KUSTOMIZE_DIR="/tmp/awx-operator-deploy"
    mkdir -p $KUSTOMIZE_DIR
    
    # Create kustomization file
    cat > $KUSTOMIZE_DIR/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/ansible/awx-operator/config/default?ref=${AWX_OPERATOR_VERSION}
images:
  - name: quay.io/ansible/awx-operator
    newTag: ${AWX_OPERATOR_VERSION}
namespace: awx
EOF
    
    kubectl apply -k $KUSTOMIZE_DIR
    rm -rf $KUSTOMIZE_DIR
    
    print_status "info" "Waiting for AWX Operator to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx
    
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
    
    # Create admin password secret first
    cat > /tmp/awx-admin-password.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: awx-admin-password
  namespace: $AWX_NAMESPACE
stringData:
  password: $ADMIN_PASSWORD
EOF
    
    kubectl apply -f /tmp/awx-admin-password.yaml
    rm -f /tmp/awx-admin-password.yaml
    
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
        # Check if AWX pods are running using grep
        local awx_task_running=$(kubectl get pods -n $AWX_NAMESPACE 2>/dev/null | grep "awx-task" | grep -c "Running" || echo "0")
        local awx_web_running=$(kubectl get pods -n $AWX_NAMESPACE 2>/dev/null | grep "awx-web" | grep -c "Running" || echo "0")
        local postgres_ready=$(kubectl get pods -n $AWX_NAMESPACE 2>/dev/null | grep "awx-postgres" | grep -c "Running" || echo "0")
        
        if [ "$awx_task_running" -gt 0 ] && [ "$awx_web_running" -gt 0 ] && [ "$postgres_ready" -gt 0 ]; then
            # Additional check: ensure awx-task is fully ready (4/4)
            local task_ready=$(kubectl get pods -n $AWX_NAMESPACE 2>/dev/null | grep "awx-task" | grep "4/4" | grep -c "Running" || echo "0")
            local web_ready=$(kubectl get pods -n $AWX_NAMESPACE 2>/dev/null | grep "awx-web" | grep "3/3" | grep -c "Running" || echo "0")
            
            if [ "$task_ready" -gt 0 ] && [ "$web_ready" -gt 0 ]; then
                print_status "success" "AWX deployment completed successfully"
                return 0
            fi
        fi
        
        echo -e "${YELLOW}⏳ Waiting for AWX pods to be ready... (${elapsed}s/${timeout}s)${NC}"
        kubectl get pods -n $AWX_NAMESPACE 2>/dev/null || echo "No pods yet..."
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
    
    # Get the actual service name (it's named after the AWX instance)
    local service_name="${AWX_INSTANCE_NAME}-service"
    
    # Start port forwarding in background with network access
    kubectl port-forward svc/$service_name -n $AWX_NAMESPACE $SERVICE_PORT:80 --address 0.0.0.0 &
    
    # Give it time to start
    sleep 5
    
    # Test local connectivity
    local test_result=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT/ 2>/dev/null)
    if [ "$test_result" = "200" ] || [ "$test_result" = "302" ]; then
        print_status "success" "Network access configured successfully"
    else
        print_status "warning" "Port forwarding started but portal not yet ready (HTTP $test_result)"
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
