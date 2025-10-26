#!/bin/bash

# AWX on Kind - Interactive Setup Manager
# A user-friendly menu system for managing AWX deployments

set -e

# Color codes for better UX
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
DOCS_DIR="$PROJECT_ROOT/docs"
CLUSTER_NAME="awx-cluster"
AWX_NAMESPACE="awx"
BACKUP_DIR="/tmp/awx-backups"

# Utility functions
print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                          ${WHITE}AWX on Kind - Setup Manager${CYAN}                         ║${NC}"
    echo -e "${CYAN}║                        ${WHITE}Interactive Cluster Management${CYAN}                       ║${NC}"
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

check_prerequisites() {
    local missing=0
    
    echo -e "${WHITE}Checking prerequisites...${NC}"
    echo ""
    
    # Check Docker
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        print_status "success" "Docker is running"
    else
        print_status "error" "Docker is not running or not installed"
        missing=1
    fi
    
    # Check kubectl
    if command -v kubectl &> /dev/null; then
        print_status "success" "kubectl is installed"
    else
        print_status "error" "kubectl is not installed"
        missing=1
    fi
    
    # Check kind
    if command -v kind &> /dev/null; then
        print_status "success" "kind is installed"
    else
        print_status "error" "kind is not installed"
        missing=1
    fi
    
    # Check helm
    if command -v helm &> /dev/null; then
        print_status "success" "helm is installed"
    else
        print_status "warning" "helm is not installed (optional)"
    fi
    
    if [ $missing -eq 1 ]; then
        echo ""
        print_status "error" "Missing prerequisites detected!"
        echo ""
        echo -e "${YELLOW}Please install missing tools:${NC}"
        echo "  Docker: brew install --cask docker"
        echo "  kubectl: brew install kubectl"
        echo "  kind: brew install kind"
        echo "  helm: brew install helm"
        echo ""
        return 1
    fi
    
    return 0
}

get_cluster_status() {
    if kind get clusters 2>/dev/null | grep -q "^$CLUSTER_NAME$"; then
        if kubectl cluster-info --context "kind-$CLUSTER_NAME" &> /dev/null; then
            echo "running"
        else
            echo "exists-not-accessible"
        fi
    else
        echo "not-exists"
    fi
}

get_awx_status() {
    if [ "$(get_cluster_status)" != "running" ]; then
        echo "no-cluster"
        return
    fi
    
    if ! kubectl get namespace "$AWX_NAMESPACE" &> /dev/null; then
        echo "no-namespace"
        return
    fi
    
    if ! kubectl get awx awx -n "$AWX_NAMESPACE" &> /dev/null; then
        echo "not-deployed"
        return
    fi
    
    local ready_pods=$(kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null | grep -E "(awx-web|awx-task)" | grep "Running" | wc -l || echo "0")
    local total_pods=$(kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null | grep -E "(awx-web|awx-task)" | wc -l || echo "0")
    
    if [ "$ready_pods" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
        if pgrep -f "kubectl port-forward.*awx-service" > /dev/null; then
            echo "ready-accessible"
        else
            echo "ready-not-accessible"
        fi
    else
        echo "deploying"
    fi
}

show_status_dashboard() {
    print_header
    echo -e "${WHITE}📊 Current Status Dashboard${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    local cluster_status=$(get_cluster_status)
    local awx_status=$(get_awx_status)
    
    # Cluster Status
    echo -e "${CYAN}🏗️  Kubernetes Cluster:${NC}"
    case $cluster_status in
        "running")
            print_status "success" "Kind cluster '$CLUSTER_NAME' is running"
            local nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
            echo "   └─ Nodes: $nodes"
            ;;
        "exists-not-accessible")
            print_status "warning" "Kind cluster '$CLUSTER_NAME' exists but not accessible"
            ;;
        "not-exists")
            print_status "info" "Kind cluster '$CLUSTER_NAME' does not exist"
            ;;
    esac
    echo ""
    
    # AWX Status
    echo -e "${CYAN}🎭 AWX Application:${NC}"
    case $awx_status in
        "no-cluster")
            print_status "info" "No cluster available for AWX"
            ;;
        "no-namespace")
            print_status "info" "AWX namespace not created"
            ;;
        "not-deployed")
            print_status "info" "AWX not deployed"
            ;;
        "deploying")
            print_status "working" "AWX is currently deploying..."
            local pods=$(kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null | grep -E "(awx-web|awx-task|postgres)" | tail -n +1)
            if [ ! -z "$pods" ]; then
                echo "$pods" | while read line; do
                    echo "   └─ $line"
                done
            fi
            ;;
        "ready-not-accessible")
            print_status "warning" "AWX is ready but not accessible (no port-forward)"
            ;;
        "ready-accessible")
            print_status "success" "AWX is running and accessible"
            if kubectl get secret awx-admin-password -n "$AWX_NAMESPACE" &>/dev/null; then
                local password=$(kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n "$AWX_NAMESPACE" | base64 --decode)
                echo "   ├─ URL: http://localhost:9080"
                echo "   ├─ Username: admin"
                echo "   └─ Password: $password"
            fi
            ;;
    esac
    echo ""
    
    # Port Status
    echo -e "${CYAN}🌐 Network Status:${NC}"
    if command -v lsof &> /dev/null; then
        if lsof -i :9080 >/dev/null 2>&1; then
            print_status "info" "Port 9080 is in use"
            lsof -i :9080 | tail -n +2 | while read line; do
                echo "   └─ $line"
            done
        else
            print_status "success" "Port 9080 is available"
        fi
    else
        print_status "info" "Port status check unavailable (lsof not found)"
    fi
    echo ""
    
    # Storage Status
    if [ "$cluster_status" = "running" ]; then
        echo -e "${CYAN}💾 Storage Status:${NC}"
        local pv_count=$(kubectl get pv 2>/dev/null | grep -c awx || echo "0")
        if [ "$pv_count" -gt 0 ]; then
            print_status "success" "Persistent volumes configured ($pv_count volumes)"
        else
            print_status "info" "No persistent volumes found"
        fi
        echo ""
    fi
}

create_cluster() {
    print_header
    echo -e "${WHITE}🏗️  Creating AWX Cluster${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Check if cluster already exists
    if kind get clusters 2>/dev/null | grep -q "^$CLUSTER_NAME$"; then
        print_status "warning" "Cluster '$CLUSTER_NAME' already exists!"
        echo ""
        echo "What would you like to do?"
        echo "1) Delete existing cluster and create new one"
        echo "2) Keep existing cluster and skip creation"
        echo "3) Return to main menu"
        echo ""
        read -p "Choose option (1-3): " choice
        
        case $choice in
            1)
                print_status "working" "Deleting existing cluster..."
                kind delete cluster --name="$CLUSTER_NAME"
                print_status "success" "Existing cluster deleted"
                ;;
            2)
                print_status "info" "Keeping existing cluster"
                press_enter
                return 0
                ;;
            3)
                return 0
                ;;
            *)
                print_status "error" "Invalid choice"
                press_enter
                return 1
                ;;
        esac
    fi
    
    # Check ports
    print_status "working" "Checking port availability..."
    if ! "$SCRIPT_DIR/check-ports.sh" >/dev/null 2>&1; then
        print_status "warning" "Port conflicts detected"
        "$SCRIPT_DIR/check-ports.sh"
        echo ""
        read -p "Continue anyway? (y/N): " continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            print_status "info" "Cluster creation cancelled"
            press_enter
            return 1
        fi
    fi
    
    # Create data directory
    print_status "working" "Creating local data directory..."
    mkdir -p /tmp/awx-data
    
    # Create cluster
    print_status "working" "Creating Kind cluster (this may take a few minutes)..."
    if kind create cluster --config="$RESOURCES_DIR/kind-cluster-config.yaml" --name="$CLUSTER_NAME"; then
        print_status "success" "Kind cluster created successfully"
    else
        print_status "error" "Failed to create Kind cluster"
        press_enter
        return 1
    fi
    
    # Create storage directories
    print_status "working" "Setting up storage directories..."
    docker exec "${CLUSTER_NAME}-worker" mkdir -p /data/postgres /data/projects 2>/dev/null || true
    docker exec "${CLUSTER_NAME}-worker2" mkdir -p /data/postgres /data/projects 2>/dev/null || true
    
    # Install ingress controller
    print_status "working" "Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    print_status "working" "Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    
    print_status "success" "Cluster created and configured successfully!"
    echo ""
    print_status "info" "Next step: Deploy AWX using option 2 from the main menu"
    press_enter
}

deploy_awx() {
    print_header
    echo -e "${WHITE}🎭 Deploying AWX${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Check cluster
    if [ "$(get_cluster_status)" != "running" ]; then
        print_status "error" "No running cluster found. Please create a cluster first."
        press_enter
        return 1
    fi
    
    # Check if AWX already exists
    if kubectl get awx awx -n "$AWX_NAMESPACE" &> /dev/null; then
        print_status "warning" "AWX instance already exists!"
        echo ""
        echo "What would you like to do?"
        echo "1) Delete existing AWX and redeploy"
        echo "2) Skip deployment and return to menu"
        echo ""
        read -p "Choose option (1-2): " choice
        
        case $choice in
            1)
                print_status "working" "Deleting existing AWX instance..."
                kubectl delete awx awx -n "$AWX_NAMESPACE" 2>/dev/null || true
                kubectl delete namespace "$AWX_NAMESPACE" 2>/dev/null || true
                sleep 5
                ;;
            2)
                return 0
                ;;
            *)
                print_status "error" "Invalid choice"
                press_enter
                return 1
                ;;
        esac
    fi
    
    # Create namespace
    print_status "working" "Creating AWX namespace..."
    kubectl create namespace "$AWX_NAMESPACE" 2>/dev/null || true
    
    # Apply persistent volumes
    print_status "working" "Creating persistent volumes..."
    kubectl apply -f "$RESOURCES_DIR/awx-pv.yaml"
    
    # Install AWX Operator
    print_status "working" "Installing AWX Operator..."
    kubectl apply -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1
    
    # Wait for operator
    print_status "working" "Waiting for AWX Operator to be ready..."
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if kubectl get deployment awx-operator-controller-manager -n "$AWX_NAMESPACE" >/dev/null 2>&1; then
            if kubectl wait --for=condition=available deployment/awx-operator-controller-manager -n "$AWX_NAMESPACE" --timeout=10s >/dev/null 2>&1; then
                break
            fi
        elif kubectl get deployment awx-operator-controller-manager -n awx-operator-system >/dev/null 2>&1; then
            if kubectl wait --for=condition=available deployment/awx-operator-controller-manager -n awx-operator-system --timeout=10s >/dev/null 2>&1; then
                break
            fi
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    echo ""
    
    # Create PostgreSQL secret
    print_status "working" "Creating PostgreSQL configuration..."
    kubectl create secret generic awx-postgres-configuration \
        --from-literal=host=awx-postgres \
        --from-literal=port=5432 \
        --from-literal=database=awx \
        --from-literal=username=awx \
        --from-literal=password=awxpass123 \
        --from-literal=type=managed \
        -n "$AWX_NAMESPACE" 2>/dev/null || true
    
    # Deploy AWX instance
    print_status "working" "Deploying AWX instance..."
    kubectl apply -f "$RESOURCES_DIR/awx-instance.yaml"
    
    # Monitor deployment
    print_status "working" "Monitoring deployment progress (this may take 5-10 minutes)..."
    echo ""
    echo "You can watch the progress with: kubectl get pods -n $AWX_NAMESPACE -w"
    echo ""
    
    local timeout=600
    local elapsed=0
    local interval=10
    
    while [ $elapsed -lt $timeout ]; do
        local ready_pods=$(kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null | grep -E "(awx-web|awx-task)" | grep "Running" | wc -l || echo "0")
        local total_pods=$(kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null | grep -E "(awx-web|awx-task)" | wc -l || echo "0")
        
        if [ "$ready_pods" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
            print_status "success" "AWX deployment completed!"
            echo ""
            
            # Get admin password
            local max_wait=60
            local wait_time=0
            while [ $wait_time -lt $max_wait ]; do
                if kubectl get secret awx-admin-password -n "$AWX_NAMESPACE" &>/dev/null; then
                    local admin_password=$(kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n "$AWX_NAMESPACE" | base64 --decode)
                    echo -e "${GREEN}🔑 AWX Admin Credentials:${NC}"
                    echo "   Username: admin"
                    echo "   Password: $admin_password"
                    echo ""
                    break
                fi
                sleep 5
                wait_time=$((wait_time + 5))
            done
            
            print_status "info" "Next step: Start port forwarding using option 3 from the main menu"
            press_enter
            return 0
        fi
        
        echo "Progress: $ready_pods/$total_pods pods ready (${elapsed}s elapsed)"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    print_status "warning" "Deployment is taking longer than expected"
    echo "Check status with: kubectl get pods -n $AWX_NAMESPACE"
    press_enter
}

start_access() {
    print_header
    echo -e "${WHITE}🌐 Starting AWX Access${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Check AWX status
    local awx_status=$(get_awx_status)
    case $awx_status in
        "no-cluster"|"no-namespace"|"not-deployed")
            print_status "error" "AWX is not deployed. Please deploy AWX first."
            press_enter
            return 1
            ;;
        "deploying")
            print_status "warning" "AWX is still deploying. Please wait for deployment to complete."
            press_enter
            return 1
            ;;
    esac
    
    # Check if port-forward is already running
    if pgrep -f "kubectl port-forward.*awx-service" > /dev/null; then
        print_status "info" "Port forwarding is already active"
    else
        print_status "working" "Starting port forwarding..."
        kubectl port-forward service/awx-service 9080:80 -n "$AWX_NAMESPACE" &
        sleep 2
        
        if pgrep -f "kubectl port-forward.*awx-service" > /dev/null; then
            print_status "success" "Port forwarding started successfully"
        else
            print_status "error" "Failed to start port forwarding"
            press_enter
            return 1
        fi
    fi
    
    # Get credentials
    if kubectl get secret awx-admin-password -n "$AWX_NAMESPACE" &>/dev/null; then
        local admin_password=$(kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n "$AWX_NAMESPACE" | base64 --decode)
        
        echo ""
        echo -e "${GREEN}🎉 AWX is now accessible!${NC}"
        echo ""
        echo -e "${CYAN}🔗 Access Information:${NC}"
        echo "   URL: http://localhost:9080"
        echo "   Username: admin"
        echo "   Password: $admin_password"
        echo ""
        
        # Test connectivity
        print_status "working" "Testing connectivity..."
        sleep 3
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:9080/api/v2/ping/ | grep -q "200"; then
            print_status "success" "AWX API is responding"
            echo ""
            echo "You can now:"
            echo "  • Open http://localhost:9080 in your browser"
            echo "  • Login with the credentials above"
            echo "  • Create organizations, projects, and job templates"
            echo ""
            echo "Note: Port forwarding will continue running in the background"
        else
            print_status "warning" "AWX may still be starting up. Please try again in a moment."
        fi
    else
        print_status "error" "Could not retrieve admin credentials"
    fi
    
    press_enter
}

stop_access() {
    print_header
    echo -e "${WHITE}🛑 Stopping AWX Access${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    if pgrep -f "kubectl port-forward.*awx-service" > /dev/null; then
        print_status "working" "Stopping port forwarding..."
        pkill -f "kubectl port-forward.*awx-service"
        sleep 1
        
        if ! pgrep -f "kubectl port-forward.*awx-service" > /dev/null; then
            print_status "success" "Port forwarding stopped"
        else
            print_status "warning" "Some port forwarding processes may still be running"
        fi
    else
        print_status "info" "No port forwarding processes found"
    fi
    
    press_enter
}

cleanup_resources() {
    print_header
    echo -e "${WHITE}🧹 Cleanup Resources${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    echo "What would you like to clean up?"
    echo ""
    echo "1) Clean up ports only (stop port-forwarding)"
    echo "2) Remove AWX deployment only (keep cluster)"
    echo "3) Remove AWX and operator (keep cluster)"
    echo "4) Complete cleanup (remove everything)"
    echo "5) Clean up backups and data"
    echo "6) Return to main menu"
    echo ""
    read -p "Choose option (1-6): " choice
    
    case $choice in
        1)
            stop_access
            ;;
        2)
            print_status "warning" "This will remove AWX deployment but keep the cluster"
            read -p "Are you sure? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                print_status "working" "Removing AWX deployment..."
                kubectl delete awx awx -n "$AWX_NAMESPACE" 2>/dev/null || true
                kubectl delete namespace "$AWX_NAMESPACE" 2>/dev/null || true
                print_status "success" "AWX deployment removed"
            fi
            ;;
        3)
            print_status "warning" "This will remove AWX and operator but keep the cluster"
            read -p "Are you sure? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                print_status "working" "Removing AWX and operator..."
                kubectl delete awx awx -n "$AWX_NAMESPACE" 2>/dev/null || true
                kubectl delete namespace "$AWX_NAMESPACE" 2>/dev/null || true
                kubectl delete -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1 2>/dev/null || true
                kubectl delete namespace awx-operator-system 2>/dev/null || true
                print_status "success" "AWX and operator removed"
            fi
            ;;
        4)
            print_status "warning" "This will remove EVERYTHING including the cluster"
            read -p "Are you sure? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                print_status "working" "Stopping port forwarding..."
                pkill -f "kubectl port-forward.*awx" 2>/dev/null || true
                
                print_status "working" "Removing Kind cluster..."
                kind delete cluster --name="$CLUSTER_NAME" 2>/dev/null || true
                
                print_status "working" "Cleaning up local data..."
                rm -rf /tmp/awx-data 2>/dev/null || true
                
                print_status "success" "Complete cleanup finished"
            fi
            ;;
        5)
            print_status "working" "Cleaning up backups and temporary data..."
            rm -rf "$BACKUP_DIR" 2>/dev/null || true
            rm -rf /tmp/awx-backup-* 2>/dev/null || true
            rm -rf /tmp/awx-data 2>/dev/null || true
            print_status "success" "Backup and data cleanup completed"
            ;;
        6)
            return 0
            ;;
        *)
            print_status "error" "Invalid choice"
            ;;
    esac
    
    press_enter
}

backup_restore() {
    print_header
    echo -e "${WHITE}💾 Backup & Restore${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    echo "Backup & Restore Options:"
    echo ""
    echo "1) Create backup"
    echo "2) List backups"
    echo "3) Restore from backup"
    echo "4) Delete old backups"
    echo "5) Return to main menu"
    echo ""
    read -p "Choose option (1-5): " choice
    
    case $choice in
        1)
            if [ "$(get_cluster_status)" != "running" ]; then
                print_status "error" "No running cluster found"
                press_enter
                return 1
            fi
            
            print_status "working" "Creating backup..."
            if "$SCRIPT_DIR/backup-awx.sh"; then
                print_status "success" "Backup created successfully"
            else
                print_status "error" "Backup failed"
            fi
            ;;
        2)
            print_status "info" "Available backups:"
            if [ -d "$BACKUP_DIR" ]; then
                ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
            else
                echo "No backup directory found"
            fi
            ;;
        3)
            print_status "info" "Restore functionality not yet implemented"
            echo "You can manually restore from backup files in $BACKUP_DIR"
            ;;
        4)
            print_status "working" "Cleaning up old backups..."
            find /tmp -name "awx-backup-*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
            print_status "success" "Old backups cleaned up"
            ;;
        5)
            return 0
            ;;
        *)
            print_status "error" "Invalid choice"
            ;;
    esac
    
    press_enter
}

update_scale() {
    print_header
    echo -e "${WHITE}⚖️  Update & Scale${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    if [ "$(get_awx_status)" = "no-cluster" ] || [ "$(get_awx_status)" = "not-deployed" ]; then
        print_status "error" "AWX is not deployed"
        press_enter
        return 1
    fi
    
    echo "Update & Scale Options:"
    echo ""
    echo "1) Scale web replicas"
    echo "2) Scale task replicas"
    echo "3) Update resource limits"
    echo "4) Restart AWX pods"
    echo "5) View current configuration"
    echo "6) Return to main menu"
    echo ""
    read -p "Choose option (1-6): " choice
    
    case $choice in
        1)
            echo "Current web replicas:"
            kubectl get awx awx -n "$AWX_NAMESPACE" -o jsonpath='{.spec.web_replicas}' 2>/dev/null || echo "Unknown"
            echo ""
            read -p "Enter new number of web replicas (1-10): " replicas
            if [[ "$replicas" =~ ^[1-9]|10$ ]]; then
                kubectl patch awx awx -n "$AWX_NAMESPACE" --type='merge' -p="{\"spec\":{\"web_replicas\":$replicas}}"
                print_status "success" "Web replicas updated to $replicas"
            else
                print_status "error" "Invalid number of replicas"
            fi
            ;;
        2)
            echo "Current task replicas:"
            kubectl get awx awx -n "$AWX_NAMESPACE" -o jsonpath='{.spec.task_replicas}' 2>/dev/null || echo "Unknown"
            echo ""
            read -p "Enter new number of task replicas (1-20): " replicas
            if [[ "$replicas" =~ ^[1-9]|1[0-9]|20$ ]]; then
                kubectl patch awx awx -n "$AWX_NAMESPACE" --type='merge' -p="{\"spec\":{\"task_replicas\":$replicas}}"
                print_status "success" "Task replicas updated to $replicas"
            else
                print_status "error" "Invalid number of replicas"
            fi
            ;;
        3)
            echo "Resource update options:"
            echo "1) Light resources (1 CPU, 2GB RAM)"
            echo "2) Medium resources (2 CPU, 4GB RAM)"
            echo "3) High resources (4 CPU, 8GB RAM)"
            read -p "Choose option (1-3): " resource_choice
            
            case $resource_choice in
                1)
                    kubectl patch awx awx -n "$AWX_NAMESPACE" --type='merge' -p='{"spec":{"web_resource_requirements":{"limits":{"cpu":"1000m","memory":"2Gi"}}}}'
                    print_status "success" "Resources set to light"
                    ;;
                2)
                    kubectl patch awx awx -n "$AWX_NAMESPACE" --type='merge' -p='{"spec":{"web_resource_requirements":{"limits":{"cpu":"2000m","memory":"4Gi"}}}}'
                    print_status "success" "Resources set to medium"
                    ;;
                3)
                    kubectl patch awx awx -n "$AWX_NAMESPACE" --type='merge' -p='{"spec":{"web_resource_requirements":{"limits":{"cpu":"4000m","memory":"8Gi"}}}}'
                    print_status "success" "Resources set to high"
                    ;;
                *)
                    print_status "error" "Invalid choice"
                    ;;
            esac
            ;;
        4)
            print_status "working" "Restarting AWX pods..."
            kubectl rollout restart deployment/awx-web -n "$AWX_NAMESPACE" 2>/dev/null || true
            kubectl rollout restart deployment/awx-task -n "$AWX_NAMESPACE" 2>/dev/null || true
            print_status "success" "AWX pods restarted"
            ;;
        5)
            echo "Current AWX configuration:"
            kubectl get awx awx -n "$AWX_NAMESPACE" -o yaml 2>/dev/null | grep -A 20 "spec:" || echo "Could not retrieve configuration"
            ;;
        6)
            return 0
            ;;
        *)
            print_status "error" "Invalid choice"
            ;;
    esac
    
    press_enter
}

troubleshoot() {
    print_header
    echo -e "${WHITE}🔧 Troubleshooting${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    echo "Troubleshooting Options:"
    echo ""
    echo "1) Run health check"
    echo "2) Run deployment verification"
    echo "3) Check pod logs"
    echo "4) Check events"
    echo "5) Check port status"
    echo "6) Reset admin password"
    echo "7) Show cluster info"
    echo "8) Return to main menu"
    echo ""
    read -p "Choose option (1-8): " choice
    
    case $choice in
        1)
            echo ""
            "$SCRIPT_DIR/health-check.sh"
            ;;
        2)
            echo ""
            "$SCRIPT_DIR/verify-deployment.sh"
            ;;
        3)
            if [ "$(get_cluster_status)" != "running" ]; then
                print_status "error" "No running cluster found"
            else
                echo "Available pods:"
                kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null | tail -n +2 | nl
                echo ""
                read -p "Enter pod number to view logs: " pod_num
                local pod_name=$(kubectl get pods -n "$AWX_NAMESPACE" --no-headers 2>/dev/null | sed -n "${pod_num}p" | awk '{print $1}')
                if [ ! -z "$pod_name" ]; then
                    echo "Logs for $pod_name:"
                    kubectl logs "$pod_name" -n "$AWX_NAMESPACE" --tail=50
                else
                    print_status "error" "Invalid pod number"
                fi
            fi
            ;;
        4)
            if [ "$(get_cluster_status)" != "running" ]; then
                print_status "error" "No running cluster found"
            else
                echo "Recent events:"
                kubectl get events -n "$AWX_NAMESPACE" --sort-by='.lastTimestamp' 2>/dev/null | tail -20
            fi
            ;;
        5)
            "$SCRIPT_DIR/check-ports.sh"
            ;;
        6)
            if [ "$(get_awx_status)" = "no-cluster" ] || [ "$(get_awx_status)" = "not-deployed" ]; then
                print_status "error" "AWX is not deployed"
            else
                print_status "working" "Resetting admin password..."
                kubectl delete secret awx-admin-password -n "$AWX_NAMESPACE" 2>/dev/null || true
                print_status "success" "Admin password reset. New password will be generated automatically."
                echo "Wait a few moments, then check status dashboard for new password"
            fi
            ;;
        7)
            if [ "$(get_cluster_status)" != "running" ]; then
                print_status "error" "No running cluster found"
            else
                echo "Cluster Information:"
                kubectl cluster-info
                echo ""
                echo "Nodes:"
                kubectl get nodes -o wide
                echo ""
                echo "Namespaces:"
                kubectl get namespaces
            fi
            ;;
        8)
            return 0
            ;;
        *)
            print_status "error" "Invalid choice"
            ;;
    esac
    
    press_enter
}

show_main_menu() {
    print_header
    
    # Show quick status
    local cluster_status=$(get_cluster_status)
    local awx_status=$(get_awx_status)
    
    echo -e "${WHITE}📋 Quick Status:${NC}"
    case $cluster_status in
        "running") echo -e "   Cluster: ${GREEN}Running${NC}" ;;
        "exists-not-accessible") echo -e "   Cluster: ${YELLOW}Exists but not accessible${NC}" ;;
        "not-exists") echo -e "   Cluster: ${RED}Not created${NC}" ;;
    esac
    
    case $awx_status in
        "ready-accessible") echo -e "   AWX: ${GREEN}Ready and accessible${NC}" ;;
        "ready-not-accessible") echo -e "   AWX: ${YELLOW}Ready but not accessible${NC}" ;;
        "deploying") echo -e "   AWX: ${BLUE}Deploying...${NC}" ;;
        "not-deployed") echo -e "   AWX: ${RED}Not deployed${NC}" ;;
        "no-cluster"|"no-namespace") echo -e "   AWX: ${RED}Not available${NC}" ;;
    esac
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo -e "${WHITE}📚 Main Menu${NC}"
    echo ""
    echo " 🏗️  Cluster Management:"
    echo "   1) Create new cluster"
    echo "   2) Deploy AWX"
    echo "   3) Start AWX access (port-forwarding)"
    echo "   4) Stop AWX access"
    echo ""
    echo " 📊 Operations:"
    echo "   5) Show status dashboard"
    echo "   6) Update & scale AWX"
    echo "   7) Backup & restore"
    echo ""
    echo " 🔧 Maintenance:"
    echo "   8) Troubleshooting"
    echo "   9) Cleanup resources"
    echo ""
    echo " ❓ Help & Info:"
    echo "   10) Prerequisites check"
    echo "   11) View documentation"
    echo "   12) Exit"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
}

view_documentation() {
    print_header
    echo -e "${WHITE}📖 Documentation${NC}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    echo "Available Documentation:"
    echo ""
    echo "1) View README.md (installation guide)"
    echo "2) View Architecture.md (system architecture)"
    echo "3) View available scripts"
    echo "4) View troubleshooting tips"
    echo "5) Return to main menu"
    echo ""
    read -p "Choose option (1-5): " choice
    
    case $choice in
        1)
            if [ -f "$DOCS_DIR/README.md" ]; then
                echo "Opening README.md..."
                less "$DOCS_DIR/README.md" || cat "$DOCS_DIR/README.md"
            else
                print_status "error" "README.md not found"
            fi
            ;;
        2)
            if [ -f "$DOCS_DIR/Architecture.md" ]; then
                echo "Opening Architecture.md..."
                less "$DOCS_DIR/Architecture.md" || cat "$DOCS_DIR/Architecture.md"
            else
                print_status "error" "Architecture.md not found"
            fi
            ;;
        3)
            echo "Available scripts in $SCRIPT_DIR:"
            ls -la "$SCRIPT_DIR"/*.sh 2>/dev/null | while read line; do
                echo "  $line"
            done
            ;;
        4)
            echo "Common Troubleshooting Tips:"
            echo ""
            echo "• If AWX is not accessible:"
            echo "  - Check if port-forwarding is running: ps aux | grep port-forward"
            echo "  - Restart port-forwarding from the main menu"
            echo ""
            echo "• If pods are stuck in Pending:"
            echo "  - Check node resources: kubectl describe nodes"
            echo "  - Check events: kubectl get events -n awx"
            echo ""
            echo "• If deployment fails:"
            echo "  - Check operator logs: kubectl logs -f deployment/awx-operator-controller-manager -n awx"
            echo "  - Verify all prerequisites are installed"
            echo ""
            echo "• For port conflicts:"
            echo "  - Run port check: ./check-ports.sh"
            echo "  - Stop conflicting processes or use different ports"
            ;;
        5)
            return 0
            ;;
        *)
            print_status "error" "Invalid choice"
            ;;
    esac
    
    press_enter
}

main() {
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    while true; do
        show_main_menu
        read -p "Enter your choice (1-12): " choice
        
        case $choice in
            1) create_cluster ;;
            2) deploy_awx ;;
            3) start_access ;;
            4) stop_access ;;
            5) show_status_dashboard ;;
            6) update_scale ;;
            7) backup_restore ;;
            8) troubleshoot ;;
            9) cleanup_resources ;;
            10) 
                print_header
                check_prerequisites
                press_enter
                ;;
            11) view_documentation ;;
            12)
                print_header
                echo -e "${GREEN}Thank you for using AWX on Kind Setup Manager!${NC}"
                echo ""
                echo "Useful commands for manual management:"
                echo "  ./health-check.sh      - Check system health"
                echo "  ./verify-deployment.sh - Verify deployment"
                echo "  ./backup-awx.sh        - Create backup"
                echo "  ./cleanup.sh           - Manual cleanup"
                echo ""
                exit 0
                ;;
            *)
                print_status "error" "Invalid choice. Please enter a number between 1-12."
                press_enter
                ;;
        esac
    done
}

# Run main function
main "$@"
