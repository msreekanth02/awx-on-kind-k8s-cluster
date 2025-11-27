#!/bin/bash

# AWX on Kind Kubernetes Cluster - Main Control Interface
# Enterprise-grade AWX deployment with complete lifecycle management

set -e

# Color codes for consistent output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration constants
CLUSTER_NAME="awx-cluster"
AWX_NAMESPACE="awx"
SERVICE_PORT=8082
BACKUP_DIR="$HOME/awx-backups"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure consistent naming across deployments
AWX_INSTANCE_NAME="awx"
DB_NAME="awx"
ADMIN_PASSWORD="password"

print_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   AWX ON KIND KUBERNETES CLUSTER                 ║${NC}"
    echo -e "${BLUE}║                  Enterprise-Grade Control Center                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "error")   echo -e "${RED}❌ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "info")    echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "menu")    echo -e "${CYAN}📋 $message${NC}" ;;
    esac
}

get_current_ip() {
    ipconfig getifaddr en0 2>/dev/null || hostname -I | cut -d' ' -f1
}

# Port management utilities
cleanup_port_forwarding() {
    print_status "info" "Cleaning up port forwarding on port $SERVICE_PORT..."
    pkill -f "kubectl.*port-forward.*awx-service" 2>/dev/null || true
    pkill -f "kubectl.*port-forward.*$SERVICE_PORT" 2>/dev/null || true
    
    # Check if port is still in use and force cleanup
    local port_pid=$(lsof -ti :$SERVICE_PORT 2>/dev/null)
    if [ ! -z "$port_pid" ]; then
        print_status "warning" "Force killing process using port $SERVICE_PORT"
        kill -9 $port_pid 2>/dev/null || true
    fi
    sleep 2
}

check_port_availability() {
    if lsof -i :$SERVICE_PORT >/dev/null 2>&1; then
        return 1  # Port is in use
    else
        return 0  # Port is available
    fi
}

get_port_forwarding_status() {
    if ps aux | grep -v grep | grep "kubectl.*port-forward.*$SERVICE_PORT" >/dev/null; then
        return 0  # Port forwarding is active
    else
        return 1  # Port forwarding is not active
    fi
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
        echo -e "${YELLOW}Please install the missing dependencies before continuing.${NC}"
        exit 1
    fi
}

cluster_status() {
    print_header
    echo -e "${YELLOW}📊 Current Cluster Status${NC}"
    echo -e "${BLUE}════════════════════════${NC}"
    echo
    
    # Check Kind cluster
    if kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        print_status "success" "Kind cluster '$CLUSTER_NAME' exists"
        
        # Check nodes
        NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
        print_status "info" "Kubernetes nodes: $NODE_COUNT"
        
        # Check AWX namespace
        if kubectl get namespace $AWX_NAMESPACE &>/dev/null; then
            print_status "success" "AWX namespace exists"
            
            # Check pods
            echo -e "\n${YELLOW}🚀 AWX Components:${NC}"
            kubectl get pods -n $AWX_NAMESPACE --no-headers | while read line; do
                name=$(echo $line | awk '{print $1}')
                ready=$(echo $line | awk '{print $2}')
                status=$(echo $line | awk '{print $3}')
                
                if [[ "$status" == "Running" ]]; then
                    print_status "success" "$name - $status ($ready)"
                elif [[ "$status" == "Completed" ]]; then
                    print_status "success" "$name - $status"
                else
                    print_status "warning" "$name - $status ($ready)"
                fi
            done
            
            # Check services
            echo -e "\n${YELLOW}🌐 Network Status:${NC}"
            if kubectl get svc awx-service -n $AWX_NAMESPACE &>/dev/null; then
                print_status "success" "AWX service configured"
                # Check if using permanent port (NodePort)
                local nodeport=$(kubectl get svc awx-service -n $AWX_NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
                if [[ -n "$nodeport" ]]; then
                    print_status "success" "Permanent port mapping: NodePort $nodeport → Host $SERVICE_PORT"
                else
                    print_status "warning" "NodePort not configured"
                fi
            else
                print_status "warning" "AWX service not found"
            fi
            
            # Check port forwarding status - only relevant if not using permanent port
            local nodeport=$(kubectl get svc awx-service -n $AWX_NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
            if [[ -z "$nodeport" ]]; then
                if get_port_forwarding_status; then
                    print_status "success" "Port forwarding active on $SERVICE_PORT"
                else
                    print_status "warning" "Port forwarding not detected"
                fi
            fi
            
            # Database status
            echo -e "\n${YELLOW}💾 Database Status:${NC}"
            USER_COUNT=$(kubectl exec -it awx-postgres-15-0 -n $AWX_NAMESPACE -- psql -U awx -t -c "SELECT COUNT(*) FROM auth_user;" 2>/dev/null | tr -d ' \n\r' || echo "0")
            if [ "$USER_COUNT" -gt "0" ]; then
                print_status "success" "Database operational with $USER_COUNT users"
            else
                print_status "warning" "Database not accessible or empty"
            fi
            
        else
            print_status "warning" "AWX namespace not found"
        fi
    else
        print_status "warning" "Kind cluster '$CLUSTER_NAME' not found"
    fi
    
    # Access URLs
    CURRENT_IP=$(get_current_ip)
    if [ ! -z "$CURRENT_IP" ]; then
        echo -e "\n${YELLOW}🔗 Access URLs:${NC}"
        echo -e "   ${BLUE}Local:${NC}    http://localhost:$SERVICE_PORT"
        echo -e "   ${BLUE}Host IP:${NC}  http://$CURRENT_IP:$SERVICE_PORT"
        echo -e "   ${BLUE}nip.io:${NC}   http://awx-${CURRENT_IP//./-}.nip.io:$SERVICE_PORT"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

deploy_cluster() {
    print_header
    echo -e "${YELLOW}🚀 Deploying AWX Cluster${NC}"
    echo -e "${BLUE}═══════════════════════${NC}"
    echo
    
    check_dependencies
    
    # Check if cluster already exists
    if kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        print_status "warning" "Cluster already exists"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            destroy_cluster_silent
        else
            return
        fi
    fi
    
    print_status "info" "Creating Kind cluster with permanent port mapping..."
    
    # Use the existing cluster config file
    kind create cluster --config="${PROJECT_DIR}/resources/kind-cluster-config.yaml" --wait=300s
    
    if [ $? -eq 0 ]; then
        print_status "success" "Kind cluster created successfully"
    else
        print_status "error" "Failed to create Kind cluster"
        return 1
    fi
    
    print_status "info" "Installing AWX Operator..."
    
    # Install AWX Operator using kustomize
    kubectl apply -k https://github.com/ansible/awx-operator/config/default/
    
    # Wait for the operator namespace to be created
    sleep 5
    
    print_status "info" "Waiting for AWX Operator to be ready..."
    # Wait for operator deployment in the AWX namespace (not awx-operator-system)
    kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx
    
    # AWX namespace is already created by the operator installation
    print_status "success" "AWX Operator ready"
    
    print_status "info" "Creating AWX instance with permanent port configuration..."
    
    # Use the existing AWX instance file
    kubectl apply -f "${PROJECT_DIR}/resources/awx-instance-simple.yaml"
    
    print_status "info" "Waiting for AWX deployment to complete..."
    
    # Wait for AWX to be ready (timeout: 15 minutes for full deployment)
    local timeout=900
    local elapsed=0
    local interval=15
    
    while [ $elapsed -lt $timeout ]; do
        # Check if both web and task pods are running
        local web_ready=$(kubectl get pods -n $AWX_NAMESPACE 2>/dev/null | grep "awx-web" | grep "Running" | wc -l | tr -d ' ')
        local task_ready=$(kubectl get pods -n $AWX_NAMESPACE 2>/dev/null | grep "awx-task" | grep "Running" | wc -l | tr -d ' ')
        
        if [[ "$web_ready" -gt "0" && "$task_ready" -gt "0" ]]; then
            # Additional check: ensure AWX is responding
            sleep 10
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT | grep -q "200"; then
                print_status "success" "AWX deployment completed successfully"
                break
            fi
        fi
        
        echo -e "${YELLOW}⏳ Waiting for AWX pods to be ready... (${elapsed}s/${timeout}s)${NC}"
        echo -e "   Web pods ready: $web_ready, Task pods ready: $task_ready"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    if [ $elapsed -ge $timeout ]; then
        print_status "error" "AWX deployment timed out"
        print_status "info" "Checking pod status for troubleshooting..."
        kubectl get pods -n $AWX_NAMESPACE
        kubectl get events -n $AWX_NAMESPACE --sort-by=.metadata.creationTimestamp | tail -10
        return 1
    fi
    
    print_status "success" "AWX cluster deployed with permanent port mapping!"
    print_status "info" "No manual port forwarding required - AWX is accessible on permanent port $SERVICE_PORT"
    
    # Verify connectivity
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT | grep -q "200"; then
        print_status "success" "AWX is accessible and responding correctly"
    else
        print_status "warning" "AWX deployment completed but connectivity check failed"
    fi
    
    show_access_info
    
    read -p "Press Enter to continue..."
}

start_port_forwarding() {
    # Check if we're using permanent port mapping
    local nodeport=$(kubectl get svc awx-service -n $AWX_NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    if [[ -n "$nodeport" ]]; then
        print_status "success" "Using permanent port mapping - no port forwarding needed"
        print_status "info" "AWX accessible via NodePort $nodeport mapped to host port $SERVICE_PORT"
        return 0
    fi
    
    # Clean up any existing port forwarding
    cleanup_port_forwarding
    
    # Check if port is available
    if ! check_port_availability; then
        print_status "warning" "Port $SERVICE_PORT is still in use after cleanup"
        return 1
    fi
    
    # Start new port forwarding in background
    print_status "info" "Starting port forwarding on port $SERVICE_PORT..."
    nohup kubectl port-forward svc/awx-service -n $AWX_NAMESPACE $SERVICE_PORT:80 --address 0.0.0.0 >/dev/null 2>&1 &
    
    # Give it time to start and verify
    sleep 3
    
    if get_port_forwarding_status; then
        print_status "success" "Port forwarding started on port $SERVICE_PORT"
        return 0
    else
        print_status "error" "Failed to start port forwarding"
        return 1
    fi
}

show_access_info() {
    local current_ip=$(get_current_ip)
    
    echo
    echo -e "${GREEN}🌐 AWX Portal Access Information:${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "   ${YELLOW}Local:${NC}    http://localhost:$SERVICE_PORT"
    if [ ! -z "$current_ip" ]; then
        echo -e "   ${YELLOW}Host IP:${NC}  http://$current_ip:$SERVICE_PORT"
        echo -e "   ${YELLOW}nip.io:${NC}   http://awx-${current_ip//./-}.nip.io:$SERVICE_PORT"
    fi
    echo
    echo -e "${GREEN}🔑 Login Credentials:${NC}"
    echo -e "   ${YELLOW}Username:${NC} admin"
    echo -e "   ${YELLOW}Password:${NC} $ADMIN_PASSWORD"
    echo
}

destroy_cluster() {
    print_header
    echo -e "${RED}💥 Destroy AWX Cluster${NC}"
    echo -e "${BLUE}═══════════════════════${NC}"
    echo
    
    if ! kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        print_status "warning" "Cluster '$CLUSTER_NAME' not found"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${RED}⚠️  WARNING: This will completely destroy the cluster and all data!${NC}"
    echo -e "${YELLOW}💡 Consider creating a backup first if you need to preserve data.${NC}"
    echo
    read -p "Are you sure you want to destroy the cluster? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        destroy_cluster_silent
        print_status "success" "Cluster destroyed successfully"
    else
        print_status "info" "Operation cancelled"
    fi
    
    read -p "Press Enter to continue..."
}

destroy_cluster_silent() {
    cleanup_port_forwarding
    
    print_status "info" "Deleting cluster..."
    kind delete cluster --name=$CLUSTER_NAME 2>/dev/null || true
    
    print_status "success" "Port $SERVICE_PORT released and cluster deleted"
}

stop_cluster() {
    print_header
    echo -e "${YELLOW}⏹️  Stop AWX Cluster${NC}"
    echo -e "${BLUE}══════════════════════${NC}"
    echo
    
    if ! kubectl get namespace $AWX_NAMESPACE &>/dev/null; then
        print_status "warning" "AWX namespace not found or cluster not running"
        read -p "Press Enter to continue..."
        return
    fi
    
    print_status "info" "Stopping AWX services..."
    
    # Check if using permanent port mapping or port forwarding
    local nodeport=$(kubectl get svc awx-service -n $AWX_NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    if [[ -z "$nodeport" ]]; then
        # Only cleanup port forwarding if not using permanent port mapping
        cleanup_port_forwarding
        print_status "success" "Port forwarding stopped and port $SERVICE_PORT released"
    else
        print_status "info" "Using permanent port mapping - no port forwarding to clean up"
    fi
    
    # Scale down deployments
    kubectl scale deployment awx-web --replicas=0 -n $AWX_NAMESPACE 2>/dev/null || true
    kubectl scale deployment awx-task --replicas=0 -n $AWX_NAMESPACE 2>/dev/null || true
    
    print_status "success" "AWX cluster stopped"
    read -p "Press Enter to continue..."
}

start_cluster() {
    print_header
    echo -e "${GREEN}▶️  Start AWX Cluster${NC}"
    echo -e "${BLUE}═════════════════════${NC}"
    echo
    
    if ! kubectl get namespace $AWX_NAMESPACE &>/dev/null; then
        print_status "warning" "AWX namespace not found. Please deploy cluster first."
        read -p "Press Enter to continue..."
        return
    fi
    
    print_status "info" "Starting AWX services..."
    
    # Scale up deployments
    kubectl scale deployment awx-web --replicas=1 -n $AWX_NAMESPACE 2>/dev/null || true
    kubectl scale deployment awx-task --replicas=1 -n $AWX_NAMESPACE 2>/dev/null || true
    
    print_status "info" "Waiting for pods to be ready..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=awx-web -n $AWX_NAMESPACE --timeout=300s 2>/dev/null || print_status "warning" "AWX web pod timeout"
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=awx-task -n $AWX_NAMESPACE --timeout=300s 2>/dev/null || print_status "warning" "AWX task pod timeout"
    
    # Check if we have permanent port mapping or need port forwarding
    local nodeport=$(kubectl get svc awx-service -n $AWX_NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    if [[ -n "$nodeport" ]]; then
        print_status "success" "AWX cluster started with permanent port mapping"
        print_status "info" "AWX accessible on permanent port $SERVICE_PORT (NodePort: $nodeport)"
    else
        # Start port forwarding for non-permanent setup
        print_status "info" "Starting port forwarding on port $SERVICE_PORT..."
        nohup kubectl port-forward svc/awx-service $SERVICE_PORT:80 -n $AWX_NAMESPACE --address=0.0.0.0 >/dev/null 2>&1 &
        sleep 3
    fi
    
    # Test connectivity
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT | grep -q "200"; then
        print_status "success" "AWX cluster started and accessible on port $SERVICE_PORT"
    else
        print_status "warning" "AWX started but connectivity check failed"
    fi
    
    read -p "Press Enter to continue..."
}

backup_data() {
    print_header
    echo -e "${YELLOW}💾 Create Data Backup${NC}"
    echo -e "${BLUE}══════════════════════${NC}"
    echo
    
    if ! kubectl get namespace $AWX_NAMESPACE &>/dev/null; then
        print_status "error" "AWX namespace not found. Is the cluster running?"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="$BACKUP_DIR/$timestamp"
    
    print_status "info" "Creating backup at: $backup_path"
    
    mkdir -p "$backup_path/database"
    mkdir -p "$backup_path/kubernetes"
    mkdir -p "$backup_path/metadata"
    
    # Backup database
    print_status "info" "Backing up database..."
    kubectl exec awx-postgres-15-0 -n $AWX_NAMESPACE -- pg_dump -U awx awx > "$backup_path/database/awx_full_backup.sql"
    
    # Backup Kubernetes resources
    print_status "info" "Backing up Kubernetes resources..."
    kubectl get all -n $AWX_NAMESPACE -o yaml > "$backup_path/kubernetes/awx_resources.yaml"
    kubectl get secrets -n $AWX_NAMESPACE -o yaml > "$backup_path/kubernetes/awx_secrets.yaml"
    kubectl get configmaps -n $AWX_NAMESPACE -o yaml > "$backup_path/kubernetes/awx_configmaps.yaml"
    
    # Create metadata
    echo "timestamp: $timestamp" > "$backup_path/metadata/backup_info.yaml"
    echo "cluster_name: $CLUSTER_NAME" >> "$backup_path/metadata/backup_info.yaml"
    echo "awx_namespace: $AWX_NAMESPACE" >> "$backup_path/metadata/backup_info.yaml"
    
    local backup_size=$(du -sh "$backup_path" | cut -f1)
    print_status "success" "Backup created successfully ($backup_size)"
    print_status "info" "Backup location: $backup_path"
    
    echo
    read -p "Press Enter to continue..."
}

restore_data() {
    print_header
    echo -e "${YELLOW}🔄 Restore Data from Backup${NC}"
    echo -e "${BLUE}═══════════════════════════════${NC}"
    echo
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_status "error" "No backup directory found at: $BACKUP_DIR"
        read -p "Press Enter to continue..."
        return
    fi
    
    # List available backups
    echo -e "${YELLOW}📋 Available Backups:${NC}"
    local backups=($(ls -1 "$BACKUP_DIR" | grep -E '^[0-9]{8}_[0-9]{6}$' | sort -r))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_status "warning" "No backups found"
        read -p "Press Enter to continue..."
        return
    fi
    
    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local backup_path="$BACKUP_DIR/$backup"
        local size=$(du -sh "$backup_path" | cut -f1)
        echo -e "   ${CYAN}$((i+1)).${NC} $backup ($size)"
    done
    echo
    
    read -p "Enter backup number to restore (1-${#backups[@]}): " -n 1 backup_choice
    echo
    
    if ! [[ "$backup_choice" =~ ^[1-9][0-9]*$ ]] || [ "$backup_choice" -gt "${#backups[@]}" ]; then
        print_status "error" "Invalid selection"
        read -p "Press Enter to continue..."
        return
    fi
    
    local selected_backup="${backups[$((backup_choice-1))]}"
    local restore_path="$BACKUP_DIR/$selected_backup"
    
    echo -e "${RED}⚠️  WARNING: This will replace all current AWX data!${NC}"
    read -p "Continue with restore from $selected_backup? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "info" "Restore cancelled"
        read -p "Press Enter to continue..."
        return
    fi
    
    if ! kubectl get namespace $AWX_NAMESPACE &>/dev/null; then
        print_status "error" "AWX namespace not found. Please deploy the cluster first."
        read -p "Press Enter to continue..."
        return
    fi
    
    print_status "info" "Stopping AWX services..."
    kubectl scale deployment awx-web awx-task -n $AWX_NAMESPACE --replicas=0
    sleep 10
    
    print_status "info" "Restoring database..."
    kubectl cp "$restore_path/database/awx_full_backup.sql" $AWX_NAMESPACE/awx-postgres-15-0:/tmp/restore.sql
    kubectl exec -it awx-postgres-15-0 -n $AWX_NAMESPACE -- psql -U postgres -c "DROP DATABASE IF EXISTS awx;"
    kubectl exec -it awx-postgres-15-0 -n $AWX_NAMESPACE -- psql -U postgres -c "CREATE DATABASE awx OWNER awx;"
    kubectl exec -it awx-postgres-15-0 -n $AWX_NAMESPACE -- psql -U awx -d awx -f /tmp/restore.sql
    kubectl exec -it awx-postgres-15-0 -n $AWX_NAMESPACE -- rm /tmp/restore.sql
    
    print_status "info" "Restarting AWX services..."
    kubectl scale deployment awx-web awx-task -n $AWX_NAMESPACE --replicas=1
    
    # Wait for services to be ready
    print_status "info" "Waiting for services to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/awx-web -n $AWX_NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/awx-task -n $AWX_NAMESPACE
    
    print_status "success" "Data restored successfully from $selected_backup"
    
    echo
    read -p "Press Enter to continue..."
}

list_backups() {
    print_header
    echo -e "${YELLOW}📋 Available Backups${NC}"
    echo -e "${BLUE}══════════════════════${NC}"
    echo
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_status "warning" "No backup directory found"
        read -p "Press Enter to continue..."
        return
    fi
    
    local backups=($(ls -1 "$BACKUP_DIR" | grep -E '^[0-9]{8}_[0-9]{6}$' | sort -r))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_status "warning" "No backups found"
    else
        echo -e "${GREEN}Found ${#backups[@]} backup(s):${NC}"
        echo
        
        for backup in "${backups[@]}"; do
            local backup_path="$BACKUP_DIR/$backup"
            local size=$(du -sh "$backup_path" | cut -f1)
            local date_formatted=$(echo "$backup" | sed 's/_/ /' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\) \([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
            
            echo -e "   ${CYAN}📦 $backup${NC}"
            echo -e "      ${YELLOW}Date:${NC} $date_formatted"
            echo -e "      ${YELLOW}Size:${NC} $size"
            
            if [ -f "$backup_path/database/awx_full_backup.sql" ]; then
                local db_size=$(du -sh "$backup_path/database/awx_full_backup.sql" | cut -f1)
                echo -e "      ${YELLOW}Database:${NC} $db_size"
            fi
            echo
        done
    fi
    
    read -p "Press Enter to continue..."
}

network_tools() {
    print_header
    echo -e "${YELLOW}🌐 Network & Access Tools${NC}"
    echo -e "${BLUE}═══════════════════════════${NC}"
    echo
    
    while true; do
        echo -e "${CYAN}1.${NC} Start/Restart Port Forwarding"
        echo -e "${CYAN}2.${NC} Stop Port Forwarding"
        echo -e "${CYAN}3.${NC} Check Port Status"
        echo -e "${CYAN}4.${NC} Show Access URLs"
        echo -e "${CYAN}5.${NC} Test Portal Connectivity"
        echo -e "${CYAN}0.${NC} Back to Main Menu"
        echo
        read -p "Select option [0-5]: " -n 1 choice
        echo
        
        case $choice in
            1)
                if start_port_forwarding; then
                    show_access_info
                fi
                ;;
            2)
                cleanup_port_forwarding
                print_status "success" "Port forwarding stopped and port $SERVICE_PORT released"
                ;;
            3)
                check_port_status
                ;;
            4)
                show_access_info
                ;;
            5)
                test_connectivity
                ;;
            0)
                break
                ;;
            *)
                print_status "error" "Invalid option"
                ;;
        esac
        echo
        read -p "Press Enter to continue..."
        print_header
        echo -e "${YELLOW}🌐 Network & Access Tools${NC}"
        echo -e "${BLUE}═══════════════════════════${NC}"
        echo
    done
}

check_port_status() {
    echo -e "${YELLOW}📊 Port Status Check${NC}"
    echo
    
    if get_port_forwarding_status; then
        print_status "success" "Port forwarding is active on port $SERVICE_PORT"
    else
        print_status "warning" "Port forwarding is not active"
    fi
    
    if check_port_availability; then
        print_status "info" "Port $SERVICE_PORT is available"
    else
        print_status "warning" "Port $SERVICE_PORT is in use"
        local port_process=$(lsof -ti :$SERVICE_PORT 2>/dev/null | head -1)
        if [ ! -z "$port_process" ]; then
            local process_name=$(ps -p $port_process -o comm= 2>/dev/null)
            print_status "info" "Process using port: $process_name (PID: $port_process)"
        fi
    fi
}

test_connectivity() {
    echo -e "${YELLOW}🔍 Testing Portal Connectivity${NC}"
    echo
    
    # Test localhost
    local localhost_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$SERVICE_PORT/ 2>/dev/null)
    if [ "$localhost_status" = "200" ]; then
        print_status "success" "localhost:$SERVICE_PORT - HTTP $localhost_status"
    else
        print_status "error" "localhost:$SERVICE_PORT - HTTP $localhost_status"
    fi
    
    # Test host IP
    local current_ip=$(get_current_ip)
    if [ ! -z "$current_ip" ]; then
        local host_status=$(curl -s -o /dev/null -w "%{http_code}" http://$current_ip:$SERVICE_PORT/ 2>/dev/null)
        if [ "$host_status" = "200" ]; then
            print_status "success" "$current_ip:$SERVICE_PORT - HTTP $host_status"
        else
            print_status "error" "$current_ip:$SERVICE_PORT - HTTP $host_status"
        fi
        
        # Test nip.io
        local nip_status=$(curl -s -o /dev/null -w "%{http_code}" http://awx-${current_ip//./-}.nip.io:$SERVICE_PORT/ 2>/dev/null)
        if [ "$nip_status" = "200" ]; then
            print_status "success" "awx-${current_ip//./-}.nip.io:$SERVICE_PORT - HTTP $nip_status"
        else
            print_status "error" "awx-${current_ip//./-}.nip.io:$SERVICE_PORT - HTTP $nip_status"
        fi
    fi
}

show_main_menu() {
    print_header
    
    echo -e "${YELLOW}🎛️  Main Menu${NC}"
    echo -e "${BLUE}═══════════${NC}"
    echo
    echo -e "${CYAN}1.${NC} 📊 Cluster Status"
    echo -e "${CYAN}2.${NC} 🚀 Deploy AWX Cluster"
    echo -e "${CYAN}3.${NC} ⏹️  Stop Cluster"
    echo -e "${CYAN}4.${NC} ▶️  Start Cluster"
    echo -e "${CYAN}5.${NC} 💥 Destroy Cluster"
    echo -e "${CYAN}6.${NC} 💾 Create Backup"
    echo -e "${CYAN}7.${NC} 🔄 Restore from Backup"
    echo -e "${CYAN}8.${NC} 📋 List Backups"
    echo -e "${CYAN}9.${NC} 🌐 Network & Access Tools"
    echo -e "${CYAN}0.${NC} 🚪 Exit"
    echo
    read -p "Select option [0-9]: " -n 1 choice
    echo
    
    case $choice in
        1) cluster_status ;;
        2) deploy_cluster ;;
        3) stop_cluster ;;
        4) start_cluster ;;
        5) destroy_cluster ;;
        6) backup_data ;;
        7) restore_data ;;
        8) list_backups ;;
        9) network_tools ;;
        0) 
            print_status "info" "Thanks for using AWX on Kind!"
            exit 0
            ;;
        *)
            print_status "error" "Invalid option. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
}

# Main execution
main() {
    # Ensure we're in the right directory
    cd "$PROJECT_DIR"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    while true; do
        show_main_menu
    done
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
