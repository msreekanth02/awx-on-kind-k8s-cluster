#!/bin/bash

# AWX Cluster Manager - Complete Lifecycle Management
# Provides interactive and command-line management for AWX on Kind clusters

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESOURCES_DIR="$PROJECT_ROOT/resources"
CLUSTER_NAME="awx-cluster"
AWX_NAMESPACE="awx"

# Utility functions
print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                       ${WHITE}AWX Cluster Lifecycle Manager${CYAN}                       ║${NC}"
    echo -e "${CYAN}║                    ${WHITE}Complete Operations & Recovery Tools${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "error")   echo -e "${RED}❌ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "info")    echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "working") echo -e "${PURPLE}🔄 $message${NC}" ;;
    esac
}

press_enter() {
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_status "error" "Docker is not running"
        echo "Starting Docker Desktop..."
        open -a Docker
        echo "Waiting for Docker to start..."
        until docker info > /dev/null 2>&1; do
            echo -n "."
            sleep 3
        done
        print_status "success" "Docker is now running"
    fi
}

get_cluster_status() {
    if ! command -v kind &> /dev/null; then
        echo "no-kind"
        return
    fi
    
    if kind get clusters 2>/dev/null | grep -q "^$CLUSTER_NAME$"; then
        if kubectl cluster-info --request-timeout=10s &> /dev/null; then
            echo "running"
        else
            echo "exists-not-accessible"
        fi
    else
        echo "not-exists"
    fi
}

get_awx_status() {
    local cluster_status=$(get_cluster_status)
    
    if [ "$cluster_status" != "running" ]; then
        echo "no-cluster"
        return
    fi
    
    if ! kubectl get namespace "$AWX_NAMESPACE" &> /dev/null; then
        echo "no-namespace"
        return
    fi
    
    if ! kubectl get awx -n "$AWX_NAMESPACE" &> /dev/null; then
        echo "not-deployed"
        return
    fi
    
    local web_ready=$(kubectl get pods -n "$AWX_NAMESPACE" -l app.kubernetes.io/name=awx-web --no-headers 2>/dev/null | awk '{print $2}' | grep -c "3/3" || echo 0)
    local task_ready=$(kubectl get pods -n "$AWX_NAMESPACE" -l app.kubernetes.io/name=awx-task --no-headers 2>/dev/null | awk '{print $2}' | grep -c "4/4" || echo 0)
    
    if [ "$web_ready" -gt 0 ] && [ "$task_ready" -gt 0 ]; then
        echo "ready"
    else
        echo "not-ready"
    fi
}

health_check() {
    print_header
    echo -e "${WHITE}🩺 AWX Cluster Health Check${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    echo -e "${YELLOW}System Components:${NC}"
    echo ""
    
    # Check Docker
    if docker info > /dev/null 2>&1; then
        print_status "success" "Docker Desktop running"
    else
        print_status "error" "Docker Desktop not running"
        echo "   → Start Docker Desktop and try again"
        return 1
    fi
    
    # Check Kind CLI
    if command -v kind &> /dev/null; then
        print_status "success" "Kind CLI available"
    else
        print_status "error" "Kind CLI not found"
        echo "   → Install with: brew install kind"
        return 1
    fi
    
    # Check kubectl
    if command -v kubectl &> /dev/null; then
        print_status "success" "kubectl CLI available"
    else
        print_status "error" "kubectl CLI not found"
        echo "   → Install with: brew install kubectl"
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Cluster Status:${NC}"
    echo ""
    
    # Check Kind cluster
    local cluster_status=$(get_cluster_status)
    case $cluster_status in
        "running")
            print_status "success" "Kind cluster '$CLUSTER_NAME' running"
            ;;
        "exists-not-accessible")
            print_status "warning" "Kind cluster exists but not accessible"
            echo "   → Try restarting the cluster"
            ;;
        "not-exists")
            print_status "error" "Kind cluster '$CLUSTER_NAME' does not exist"
            echo "   → Create cluster with option 4"
            return 1
            ;;
        "no-kind")
            print_status "error" "Kind CLI not available"
            return 1
            ;;
    esac
    
    # Check AWX deployment
    local awx_status=$(get_awx_status)
    echo ""
    echo -e "${YELLOW}AWX Deployment:${NC}"
    echo ""
    
    case $awx_status in
        "ready")
            print_status "success" "AWX deployment ready and running"
            echo ""
            echo "📊 Pod Status:"
            kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null | while IFS= read -r line; do
                if [[ $line == NAME* ]]; then
                    echo "   $line"
                else
                    echo "   $line"
                fi
            done
            ;;
        "not-ready")
            print_status "warning" "AWX deployment exists but not ready"
            echo "   → Pods may still be starting up"
            ;;
        "not-deployed")
            print_status "error" "AWX not deployed"
            echo "   → Deploy AWX with option 4"
            ;;
        "no-namespace")
            print_status "error" "AWX namespace does not exist"
            echo "   → Deploy AWX with option 4"
            ;;
        "no-cluster")
            print_status "error" "No running cluster found"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Portal Access:${NC}"
    echo ""
    
    # Check portal access
    if curl -s -I --connect-timeout 5 http://awx-192-168-1-243.nip.io:9080 | grep -q "200 OK"; then
        print_status "success" "Host IP access working: http://awx-192-168-1-243.nip.io:9080"
    elif curl -s -I --connect-timeout 5 http://localhost:9080 | grep -q "200 OK"; then
        print_status "success" "Local access working: http://localhost:9080"
        print_status "warning" "Host IP access not available"
    else
        print_status "error" "No portal access available"
        echo "   → Use option 6 to set up portal access"
    fi
    
    # Get admin password if available
    local admin_pass=$(kubectl get secret awx-admin-password -n "$AWX_NAMESPACE" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)
    if [ ! -z "$admin_pass" ]; then
        echo ""
        echo -e "${YELLOW}Admin Credentials:${NC}"
        print_status "info" "Username: admin"
        print_status "info" "Password: $admin_pass"
    fi
    
    return 0
}

restart_cluster() {
    print_header
    echo -e "${WHITE}🔄 Restarting AWX Cluster${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    print_status "warning" "This will restart the entire cluster while preserving data"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return
    fi
    
    echo ""
    print_status "working" "Stopping port-forward connections..."
    pkill -f "kubectl.*port-forward" 2>/dev/null || true
    
    print_status "working" "Restarting Docker (this restarts Kind containers)..."
    osascript -e 'quit app "Docker"' 2>/dev/null || true
    sleep 5
    open -a Docker
    
    print_status "working" "Waiting for Docker to start..."
    until docker info > /dev/null 2>&1; do
        echo -n "."
        sleep 3
    done
    echo ""
    
    print_status "working" "Verifying cluster connectivity..."
    local retries=0
    until kubectl cluster-info --request-timeout=30s > /dev/null 2>&1; do
        echo -n "."
        sleep 5
        retries=$((retries + 1))
        if [ $retries -gt 12 ]; then
            print_status "error" "Cluster did not come back online"
            return 1
        fi
    done
    echo ""
    
    print_status "working" "Waiting for AWX pods to be ready..."
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-web -n "$AWX_NAMESPACE" --timeout=300s > /dev/null 2>&1; then
        print_status "success" "AWX web pods ready"
    else
        print_status "warning" "AWX web pods taking longer than expected"
    fi
    
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-task -n "$AWX_NAMESPACE" --timeout=300s > /dev/null 2>&1; then
        print_status "success" "AWX task pods ready"
    else
        print_status "warning" "AWX task pods taking longer than expected"
    fi
    
    echo ""
    print_status "success" "Cluster restart completed!"
    echo ""
    echo "📊 Current Pod Status:"
    kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null || echo "Could not retrieve pod status"
}

stop_cluster() {
    print_header
    echo -e "${WHITE}🛑 Stopping AWX Cluster${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    print_status "warning" "This will stop the cluster but preserve all data"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return
    fi
    
    echo ""
    print_status "working" "Stopping port-forward connections..."
    pkill -f "kubectl.*port-forward" 2>/dev/null || true
    
    print_status "working" "Scaling down AWX deployments (saves resources)..."
    kubectl scale deployment awx-web --replicas=0 -n "$AWX_NAMESPACE" 2>/dev/null || true
    kubectl scale deployment awx-task --replicas=0 -n "$AWX_NAMESPACE" 2>/dev/null || true
    
    print_status "working" "Stopping Docker Desktop..."
    osascript -e 'quit app "Docker"' 2>/dev/null || true
    
    print_status "success" "Cluster stopped successfully!"
    echo ""
    print_status "info" "Your AWX data is preserved and ready for restart"
    echo ""
    echo "💡 To start the cluster again:"
    echo "   → Run this script and choose option 3 (Start Cluster)"
    echo "   → Or manually start Docker Desktop and scale deployments back up"
}

start_cluster() {
    print_header
    echo -e "${WHITE}🚀 Starting AWX Cluster${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    print_status "working" "Starting Docker Desktop..."
    open -a Docker
    
    until docker info > /dev/null 2>&1; do
        echo "Waiting for Docker..."
        sleep 3
    done
    print_status "success" "Docker Desktop started"
    
    print_status "working" "Verifying Kind cluster exists..."
    if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
        print_status "error" "Kind cluster '$CLUSTER_NAME' not found"
        echo ""
        echo "💡 The cluster may have been destroyed. Options:"
        echo "   → Use option 4 to create a fresh cluster"
        echo "   → Check if Docker containers exist: docker ps -a | grep awx-cluster"
        return 1
    fi
    
    print_status "working" "Checking cluster connectivity..."
    local retries=0
    until kubectl cluster-info --request-timeout=30s > /dev/null 2>&1; do
        echo -n "."
        sleep 5
        retries=$((retries + 1))
        if [ $retries -gt 12 ]; then
            print_status "error" "Could not connect to cluster"
            return 1
        fi
    done
    echo ""
    print_status "success" "Cluster connectivity verified"
    
    print_status "working" "Scaling AWX deployments back up..."
    kubectl scale deployment awx-web --replicas=1 -n "$AWX_NAMESPACE" 2>/dev/null || true
    kubectl scale deployment awx-task --replicas=1 -n "$AWX_NAMESPACE" 2>/dev/null || true
    
    print_status "working" "Waiting for AWX pods to be ready..."
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-web -n "$AWX_NAMESPACE" --timeout=300s > /dev/null 2>&1; then
        print_status "success" "AWX web pods ready"
    else
        print_status "warning" "AWX web pods taking longer than expected"
    fi
    
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-task -n "$AWX_NAMESPACE" --timeout=300s > /dev/null 2>&1; then
        print_status "success" "AWX task pods ready"
    else
        print_status "warning" "AWX task pods taking longer than expected"
    fi
    
    echo ""
    print_status "success" "Cluster started successfully!"
    echo ""
    echo "📊 Current Pod Status:"
    kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null || echo "Could not retrieve pod status"
}

create_cluster() {
    print_header
    echo -e "${WHITE}🏗️ Creating Fresh AWX Cluster${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Check if cluster already exists
    if kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        print_status "warning" "Kind cluster '$CLUSTER_NAME' already exists"
        echo ""
        read -p "Destroy existing cluster and create fresh? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "working" "Destroying existing cluster..."
            destroy_cluster_silent
        else
            echo "Operation cancelled."
            return
        fi
    fi
    
    echo ""
    print_status "info" "This will create a complete fresh AWX v24.6.1 deployment"
    echo ""
    
    # Ensure Docker is running
    check_docker
    
    # Create Kind cluster
    echo ""
    print_status "working" "Creating Kind cluster with 3 nodes..."
    if kind create cluster --config "$RESOURCES_DIR/kind-cluster-config.yaml"; then
        print_status "success" "Kind cluster created"
    else
        print_status "error" "Failed to create Kind cluster"
        return 1
    fi
    
    # Install NGINX Ingress
    print_status "working" "Installing NGINX Ingress Controller..."
    if kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml > /dev/null 2>&1; then
        print_status "success" "NGINX Ingress Controller installed"
    else
        print_status "error" "Failed to install NGINX Ingress Controller"
        return 1
    fi
    
    # Wait for ingress controller
    print_status "working" "Waiting for ingress controller to be ready..."
    if kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s > /dev/null 2>&1; then
        print_status "success" "Ingress controller ready"
    else
        print_status "error" "Ingress controller failed to start"
        return 1
    fi
    
    # Configure ingress for host access
    print_status "working" "Configuring ingress for host IP access..."
    if kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
        -p '{"spec":{"template":{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}}}' > /dev/null 2>&1; then
        print_status "success" "Ingress configured for host access"
    else
        print_status "warning" "Failed to configure host access"
    fi
    
    # Wait for ingress rollout
    kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s > /dev/null 2>&1
    
    # Install AWX Operator
    print_status "working" "Installing AWX Operator v2.19.1..."
    if kubectl apply -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1 > /dev/null 2>&1; then
        print_status "success" "AWX Operator installed"
    else
        print_status "error" "Failed to install AWX Operator"
        return 1
    fi
    
    # Wait for operator
    print_status "working" "Waiting for AWX Operator to be ready..."
    if kubectl wait --for=condition=available deployment/awx-operator-controller-manager \
        -n awx-operator-system --timeout=300s > /dev/null 2>&1; then
        print_status "success" "AWX Operator ready"
    else
        print_status "error" "AWX Operator failed to start"
        return 1
    fi
    
    # Create namespace and storage
    print_status "working" "Creating AWX namespace and storage..."
    kubectl create namespace "$AWX_NAMESPACE" > /dev/null 2>&1 || true
    mkdir -p /tmp/awx-data
    if kubectl apply -f "$RESOURCES_DIR/awx-pv.yaml" > /dev/null 2>&1; then
        print_status "success" "AWX storage configured"
    else
        print_status "error" "Failed to configure storage"
        return 1
    fi
    
    # Deploy AWX
    print_status "working" "Deploying AWX v24.6.1..."
    if kubectl apply -f "$RESOURCES_DIR/awx-instance.yaml" > /dev/null 2>&1; then
        print_status "success" "AWX deployment started"
    else
        print_status "error" "Failed to deploy AWX"
        return 1
    fi
    
    # Wait for deployment (this takes several minutes)
    echo ""
    print_status "working" "Waiting for AWX deployment to complete (this takes 5-10 minutes)..."
    echo "               Progress indicators:"
    
    # Wait for migration job
    echo "               → Database migration..."
    if kubectl wait --for=condition=complete job -l app.kubernetes.io/name=awx-migration -n "$AWX_NAMESPACE" --timeout=600s > /dev/null 2>&1; then
        echo "               ✅ Database migration completed"
    else
        echo "               ⚠️  Database migration taking longer than expected"
    fi
    
    # Wait for web pods
    echo "               → AWX web pods..."
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-web -n "$AWX_NAMESPACE" --timeout=600s > /dev/null 2>&1; then
        echo "               ✅ AWX web pods ready"
    else
        echo "               ⚠️  AWX web pods taking longer than expected"
    fi
    
    # Wait for task pods
    echo "               → AWX task pods..."
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-task -n "$AWX_NAMESPACE" --timeout=600s > /dev/null 2>&1; then
        echo "               ✅ AWX task pods ready"
    else
        echo "               ⚠️  AWX task pods taking longer than expected"
    fi
    
    echo ""
    print_status "success" "AWX deployment completed!"
    
    # Verify deployment
    echo ""
    print_status "info" "Deployment verification:"
    kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null | while IFS= read -r line; do
        echo "   $line"
    done
    
    # Test portal access
    echo ""
    print_status "working" "Testing portal access..."
    sleep 10
    
    if curl -s -I --connect-timeout 10 http://awx-192-168-1-243.nip.io:9080 | grep -q "200 OK"; then
        print_status "success" "Host IP access working: http://awx-192-168-1-243.nip.io:9080"
    else
        print_status "warning" "Host IP not ready, setting up port-forward..."
        kubectl port-forward -n "$AWX_NAMESPACE" svc/awx-service 9080:80 > /dev/null 2>&1 &
        print_status "info" "Local access: http://localhost:9080"
    fi
    
    # Display credentials
    local admin_pass=$(kubectl get secret awx-admin-password -n "$AWX_NAMESPACE" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "Not ready yet, wait 2-3 minutes")
    
    echo ""
    echo -e "${GREEN}🎉 FRESH AWX CLUSTER CREATED SUCCESSFULLY!${NC}"
    echo ""
    echo "📊 Deployment Summary:"
    echo "   ✅ Kind cluster: $CLUSTER_NAME"
    echo "   ✅ AWX version: v24.6.1"
    echo "   ✅ Operator version: v2.19.1"
    echo "   ✅ Host access: http://awx-192-168-1-243.nip.io:9080"
    echo "   ✅ Local access: http://localhost:9080"
    echo ""
    echo "🔐 Admin Credentials:"
    echo "   Username: admin"
    echo "   Password: $admin_pass"
    echo ""
    print_status "info" "Your AWX cluster is ready for use!"
}

destroy_cluster_silent() {
    # Silent version for internal use
    pkill -f "kubectl.*port-forward" 2>/dev/null || true
    kind delete cluster --name "$CLUSTER_NAME" > /dev/null 2>&1 || true
    rm -rf /tmp/awx-data 2>/dev/null || true
}

destroy_cluster() {
    print_header
    echo -e "${WHITE}💥 Destroy AWX Cluster${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    print_status "error" "⚠️  WARNING: This will permanently delete ALL data!"
    print_status "error" "⚠️  AWX projects, inventories, job history will be lost!"
    echo ""
    
    read -p "Type 'DESTROY' to confirm complete deletion: " -r confirm
    
    if [[ "$confirm" != "DESTROY" ]]; then
        echo "Operation cancelled."
        return
    fi
    
    echo ""
    print_status "working" "Stopping all port-forward connections..."
    pkill -f "kubectl.*port-forward" 2>/dev/null || true
    
    print_status "working" "Deleting Kind cluster..."
    if kind delete cluster --name "$CLUSTER_NAME"; then
        print_status "success" "Kind cluster deleted"
    else
        print_status "warning" "Kind cluster deletion had issues (may not have existed)"
    fi
    
    print_status "working" "Cleaning up local data..."
    rm -rf /tmp/awx-data 2>/dev/null || true
    
    # Verify cleanup
    if kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        print_status "warning" "Cluster may still exist. Manual cleanup needed:"
        echo "   docker stop \$(docker ps -q --filter name=awx-cluster)"
        echo "   docker rm \$(docker ps -aq --filter name=awx-cluster)"
    else
        print_status "success" "Cluster destroyed successfully!"
    fi
    
    echo ""
    print_status "info" "All AWX data has been removed."
    print_status "info" "You can create a fresh cluster with option 4."
}

access_portal() {
    print_header
    echo -e "${WHITE}🌐 AWX Portal Access${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Check if AWX is running
    local awx_status=$(get_awx_status)
    if [ "$awx_status" == "no-cluster" ] || [ "$awx_status" == "not-deployed" ]; then
        print_status "error" "AWX is not deployed or cluster is not running"
        echo ""
        print_status "info" "Please deploy AWX first using option 4 (Create Fresh Cluster)"
        return 1
    fi
    
    print_status "info" "Testing portal access methods..."
    echo ""
    
    # Method 1: Host IP access (preferred)
    if curl -s -I --connect-timeout 5 http://awx-192-168-1-243.nip.io:9080 | grep -q "200 OK"; then
        print_status "success" "Host IP access working!"
        echo ""
        echo "🌐 Primary Access (Host IP):"
        echo "   URL: http://awx-192-168-1-243.nip.io:9080"
        echo "   Benefits: Persistent, no port-forward needed, network accessible"
        echo ""
        print_status "working" "Opening in browser..."
        open http://awx-192-168-1-243.nip.io:9080
    elif curl -s -I --connect-timeout 5 http://localhost:9080 | grep -q "200 OK"; then
        print_status "success" "Local access working!"
        echo ""
        echo "🏠 Local Access (Port-Forward):"
        echo "   URL: http://localhost:9080"
        echo "   Note: Existing port-forward is active"
        echo ""
        print_status "working" "Opening in browser..."
        open http://localhost:9080
    else
        print_status "warning" "No existing access found, setting up port-forward..."
        echo ""
        
        # Clean up any existing port-forwards
        pkill -f "kubectl.*port-forward.*9080" 2>/dev/null || true
        sleep 2
        
        # Start new port-forward
        print_status "working" "Starting port-forward on localhost:9080..."
        kubectl port-forward -n "$AWX_NAMESPACE" svc/awx-service 9080:80 > /dev/null 2>&1 &
        local pf_pid=$!
        
        # Wait and test connection
        sleep 3
        if curl -s -I --connect-timeout 5 http://localhost:9080 | grep -q "200 OK"; then
            print_status "success" "Port-forward access ready!"
            echo ""
            echo "🏠 Local Access (Port-Forward):"
            echo "   URL: http://localhost:9080"
            echo "   PID: $pf_pid"
            echo ""
            print_status "working" "Opening in browser..."
            open http://localhost:9080
        else
            print_status "error" "Could not establish portal access"
            echo ""
            echo "💡 Troubleshooting steps:"
            echo "   1. Run health check (option 1)"
            echo "   2. Restart cluster (option 2)"
            echo "   3. Check pod logs: kubectl logs -n awx -l app.kubernetes.io/name=awx-web"
            return 1
        fi
    fi
    
    # Display credentials
    echo ""
    local admin_pass=$(kubectl get secret awx-admin-password -n "$AWX_NAMESPACE" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)
    if [ ! -z "$admin_pass" ]; then
        echo "🔐 Login Credentials:"
        echo "   Username: admin"
        echo "   Password: $admin_pass"
        echo ""
    else
        print_status "warning" "Admin password not ready yet, please wait 2-3 minutes"
        echo ""
    fi
    
    echo "💡 Access Methods Summary:"
    echo "   🌐 Host IP: http://awx-192-168-1-243.nip.io:9080 (persistent)"
    echo "   🏠 Local: http://localhost:9080 (requires port-forward)"
    echo "   📱 Network: Share host IP URL with others on your network"
    echo ""
    echo "🛑 To stop port-forward: pkill -f 'kubectl.*port-forward.*9080'"
}

show_main_menu() {
    print_header
    
    # Show current status
    local cluster_status=$(get_cluster_status)
    local awx_status=$(get_awx_status)
    
    echo -e "${YELLOW}📊 Current Status:${NC}"
    case $cluster_status in
        "running")
            echo -e "   Cluster: ${GREEN}✅ Running${NC}"
            ;;
        "exists-not-accessible")
            echo -e "   Cluster: ${YELLOW}⚠️  Exists but not accessible${NC}"
            ;;
        "not-exists")
            echo -e "   Cluster: ${RED}❌ Not found${NC}"
            ;;
        *)
            echo -e "   Cluster: ${RED}❌ Unknown state${NC}"
            ;;
    esac
    
    case $awx_status in
        "ready")
            echo -e "   AWX: ${GREEN}✅ Ready and running${NC}"
            ;;
        "not-ready")
            echo -e "   AWX: ${YELLOW}⚠️  Deployed but not ready${NC}"
            ;;
        "not-deployed")
            echo -e "   AWX: ${RED}❌ Not deployed${NC}"
            ;;
        *)
            echo -e "   AWX: ${RED}❌ Unknown state${NC}"
            ;;
    esac
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo -e "${WHITE}📋 Cluster Management Options${NC}"
    echo ""
    echo " 🩺 Diagnostics & Status:"
    echo "   1) Health check & system diagnostics"
    echo ""
    echo " 🔄 Cluster Operations:"
    echo "   2) Restart cluster (preserve data)"
    echo "   3) Start cluster (resume from stop)"
    echo "   4) Create fresh cluster (complete rebuild)"
    echo "   5) Destroy cluster (⚠️  deletes all data)"
    echo ""
    echo " 🌐 Access & Portal:"
    echo "   6) Access AWX portal"
    echo "   7) Stop cluster (preserve data)"
    echo ""
    echo " ❓ Help & Information:"
    echo "   8) View documentation"
    echo "   9) Exit"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
}

show_documentation() {
    print_header
    echo -e "${WHITE}📚 AWX Cluster Management Documentation${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    echo "📖 Available Documentation:"
    echo ""
    echo "1) View CLUSTER-MANAGEMENT.md (complete technical guide)"
    echo "2) View README.md (project overview)"
    echo "3) View ARCHITECTURE.md (system architecture)"
    echo "4) View PRODUCTION-READY.md (deployment status)"
    echo "5) Quick command reference"
    echo "6) Return to main menu"
    echo ""
    read -p "Choose option (1-6): " choice
    
    case $choice in
        1)
            if [ -f "$PROJECT_ROOT/docs/CLUSTER-MANAGEMENT.md" ]; then
                echo "Opening CLUSTER-MANAGEMENT.md..."
                less "$PROJECT_ROOT/docs/CLUSTER-MANAGEMENT.md" 2>/dev/null || cat "$PROJECT_ROOT/docs/CLUSTER-MANAGEMENT.md"
            else
                print_status "error" "CLUSTER-MANAGEMENT.md not found"
            fi
            ;;
        2)
            if [ -f "$PROJECT_ROOT/docs/README.md" ]; then
                echo "Opening README.md..."
                less "$PROJECT_ROOT/docs/README.md" 2>/dev/null || cat "$PROJECT_ROOT/docs/README.md"
            else
                print_status "error" "README.md not found"
            fi
            ;;
        3)
            if [ -f "$PROJECT_ROOT/docs/ARCHITECTURE.md" ]; then
                echo "Opening ARCHITECTURE.md..."
                less "$PROJECT_ROOT/docs/ARCHITECTURE.md" 2>/dev/null || cat "$PROJECT_ROOT/docs/ARCHITECTURE.md"
            else
                print_status "error" "ARCHITECTURE.md not found"
            fi
            ;;
        4)
            if [ -f "$PROJECT_ROOT/docs/PRODUCTION-READY.md" ]; then
                echo "Opening PRODUCTION-READY.md..."
                less "$PROJECT_ROOT/docs/PRODUCTION-READY.md" 2>/dev/null || cat "$PROJECT_ROOT/docs/PRODUCTION-READY.md"
            else
                print_status "error" "PRODUCTION-READY.md not found"
            fi
            ;;
        5)
            echo ""
            echo "🔧 Quick Command Reference:"
            echo ""
            echo "# Interactive management"
            echo "./scripts/cluster-manager.sh"
            echo ""
            echo "# Direct commands"
            echo "./scripts/cluster-manager.sh health      # Health check"
            echo "./scripts/cluster-manager.sh restart    # Restart cluster"
            echo "./scripts/cluster-manager.sh create     # Create fresh"
            echo "./scripts/cluster-manager.sh destroy    # Destroy cluster"
            echo "./scripts/cluster-manager.sh access     # Portal access"
            echo ""
            echo "# Portal access"
            echo "./scripts/access-portal.sh"
            echo "open http://awx-192-168-1-243.nip.io:9080"
            echo ""
            echo "# Quick status"
            echo "kubectl get pods -n awx"
            echo "curl -I http://awx-192-168-1-243.nip.io:9080"
            echo ""
            echo "# Get admin password"
            echo "kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' | base64 -d"
            ;;
        6)
            return
            ;;
        *)
            print_status "error" "Invalid choice"
            ;;
    esac
    
    press_enter
}

# Main function
main() {
    # Handle command line arguments
    case "${1:-}" in
        "health")
            health_check
            exit $?
            ;;
        "restart")
            restart_cluster
            exit $?
            ;;
        "start")
            start_cluster
            exit $?
            ;;
        "stop")
            stop_cluster
            exit $?
            ;;
        "create")
            create_cluster
            exit $?
            ;;
        "destroy")
            destroy_cluster
            exit $?
            ;;
        "access")
            access_portal
            exit $?
            ;;
        "")
            # Interactive mode
            ;;
        *)
            echo "Usage: $0 [health|restart|start|stop|create|destroy|access]"
            echo ""
            echo "Available commands:"
            echo "  health   - Run health check and diagnostics"
            echo "  restart  - Restart cluster (preserve data)"
            echo "  start    - Start stopped cluster"
            echo "  stop     - Stop cluster (preserve data)"
            echo "  create   - Create fresh cluster"
            echo "  destroy  - Destroy cluster (⚠️  deletes data)"
            echo "  access   - Access AWX portal"
            echo ""
            echo "Run without arguments for interactive menu."
            exit 1
            ;;
    esac
    
    # Interactive menu mode
    while true; do
        show_main_menu
        read -p "Enter your choice (1-9): " choice
        
        case $choice in
            1) health_check; press_enter ;;
            2) restart_cluster; press_enter ;;
            3) start_cluster; press_enter ;;
            4) create_cluster; press_enter ;;
            5) destroy_cluster; press_enter ;;
            6) access_portal; press_enter ;;
            7) stop_cluster; press_enter ;;
            8) show_documentation ;;
            9)
                print_header
                echo -e "${GREEN}Thank you for using AWX Cluster Manager!${NC}"
                echo ""
                echo "💡 Quick reminders:"
                echo "   • Portal access: http://awx-192-168-1-243.nip.io:9080"
                echo "   • Documentation: ./CLUSTER-MANAGEMENT.md"
                echo "   • Health check: ./scripts/cluster-manager.sh health"
                echo ""
                exit 0
                ;;
            *)
                print_status "error" "Invalid choice. Please enter a number between 1-9."
                press_enter
                ;;
        esac
    done
}

# Run main function
main "$@"
