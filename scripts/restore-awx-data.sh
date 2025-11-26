#!/bin/bash

# AWX Data Restore Script
# Restores AWX data from backups created outside the project directory

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
BACKUP_BASE_DIR="$HOME/awx-backups"
AWX_NAMESPACE="awx"

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
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        ${GREEN}AWX Data Restore Tool${BLUE}                             ║${NC}"
    echo -e "${BLUE}║                   ${GREEN}Restore from external backup directory${BLUE}                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# List available backups
list_backups() {
    print_status "info" "Available backups in $BACKUP_BASE_DIR:"
    echo ""
    
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        print_status "error" "No backup directory found at $BACKUP_BASE_DIR"
        exit 1
    fi
    
    local count=0
    for backup_dir in "$BACKUP_BASE_DIR"/*/; do
        if [ -d "$backup_dir" ]; then
            local backup_name=$(basename "$backup_dir")
            local backup_date=$(echo "$backup_name" | sed 's/_/ /' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
            local size=$(du -sh "$backup_dir" 2>/dev/null | cut -f1 || echo "Unknown")
            
            echo "   📁 $backup_name (Size: $size)"
            if [ -f "$backup_dir/metadata/backup_info.txt" ]; then
                local creation_date=$(grep "Backup Date:" "$backup_dir/metadata/backup_info.txt" 2>/dev/null | cut -d: -f2- | xargs || echo "Unknown")
                echo "      📅 Created: $creation_date"
            fi
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        print_status "error" "No backups found"
        echo ""
        echo "💡 To create a backup first:"
        echo "   ./scripts/backup-awx-data.sh"
        exit 1
    fi
    
    echo ""
    print_status "info" "Found $count backup(s)"
}

# Select backup to restore
select_backup() {
    if [ -n "$1" ]; then
        SELECTED_BACKUP="$1"
        BACKUP_DIR="$BACKUP_BASE_DIR/$SELECTED_BACKUP"
    else
        echo "Enter the backup timestamp to restore (e.g., 20241126_143022):"
        read -r SELECTED_BACKUP
        BACKUP_DIR="$BACKUP_BASE_DIR/$SELECTED_BACKUP"
    fi
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_status "error" "Backup directory not found: $BACKUP_DIR"
        exit 1
    fi
    
    print_status "success" "Selected backup: $SELECTED_BACKUP"
    
    # Show backup info if available
    if [ -f "$BACKUP_DIR/metadata/backup_info.txt" ]; then
        echo ""
        print_status "info" "Backup Information:"
        cat "$BACKUP_DIR/metadata/backup_info.txt" | head -15
    fi
}

# Check prerequisites
check_prerequisites() {
    print_status "info" "Checking prerequisites..."
    
    # Check if cluster exists and is accessible
    if ! kubectl cluster-info --request-timeout=10s &> /dev/null; then
        print_status "error" "Kubernetes cluster is not accessible"
        echo ""
        echo "💡 Please create and start your cluster first:"
        echo "   ./scripts/cluster-manager.sh create"
        exit 1
    fi
    
    # Check if AWX namespace exists
    if ! kubectl get namespace "$AWX_NAMESPACE" &> /dev/null; then
        print_status "error" "AWX namespace not found"
        echo ""
        echo "💡 Please deploy AWX first:"
        echo "   ./scripts/cluster-manager.sh create"
        exit 1
    fi
    
    print_status "success" "Prerequisites met"
}

# Restore database
restore_database() {
    print_status "info" "🗃️  Restoring database..."
    
    local pg_pod=$(kubectl get pods -n "$AWX_NAMESPACE" -l app.kubernetes.io/name=postgres-15 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pg_pod" ]; then
        print_status "error" "PostgreSQL pod not found"
        return 1
    fi
    
    if [ ! -f "$BACKUP_DIR/database/awx_full_backup.sql" ]; then
        print_status "error" "Database backup file not found"
        return 1
    fi
    
    print_status "warning" "This will overwrite the current database!"
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "info" "Database restore cancelled"
        return 0
    fi
    
    # Restore database
    kubectl exec -i -n "$AWX_NAMESPACE" "$pg_pod" -- psql -U postgres -d awx < "$BACKUP_DIR/database/awx_full_backup.sql" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_status "success" "Database restored successfully"
        
        # Restart AWX pods to pick up restored data
        print_status "info" "Restarting AWX pods to apply restored data..."
        kubectl rollout restart deployment/awx-web -n "$AWX_NAMESPACE" > /dev/null 2>&1 || true
        kubectl rollout restart deployment/awx-task -n "$AWX_NAMESPACE" > /dev/null 2>&1 || true
        
        print_status "success" "AWX pods restarted"
    else
        print_status "error" "Database restore failed"
        return 1
    fi
}

# Restore persistent files
restore_files() {
    print_status "info" "📁 Restoring persistent files..."
    
    local task_pod=$(kubectl get pods -n "$AWX_NAMESPACE" -l app.kubernetes.io/name=awx-task -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$task_pod" ]; then
        print_status "warning" "No AWX task pods found, skipping file restore"
        return 0
    fi
    
    # Wait for pod to be ready
    kubectl wait --for=condition=ready pod "$task_pod" -n "$AWX_NAMESPACE" --timeout=120s > /dev/null 2>&1 || true
    
    # Restore projects if backup exists
    if [ -f "$BACKUP_DIR/files/awx_projects.tar.gz" ]; then
        kubectl exec -i -n "$AWX_NAMESPACE" "$task_pod" -- tar -xzf - -C / < "$BACKUP_DIR/files/awx_projects.tar.gz" 2>/dev/null || true
        print_status "success" "Projects restored"
    fi
    
    # Restore receptor data if backup exists
    if [ -f "$BACKUP_DIR/files/awx_receptor.tar.gz" ]; then
        kubectl exec -i -n "$AWX_NAMESPACE" "$task_pod" -- tar -xzf - -C / < "$BACKUP_DIR/files/awx_receptor.tar.gz" 2>/dev/null || true
        print_status "success" "Receptor data restored"
    fi
    
    print_status "success" "File restoration completed"
}

# Verify restoration
verify_restore() {
    print_status "info" "🔍 Verifying restoration..."
    
    # Wait for pods to be ready
    print_status "info" "Waiting for AWX pods to be ready..."
    
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-web -n "$AWX_NAMESPACE" --timeout=180s > /dev/null 2>&1; then
        print_status "success" "AWX web pods are ready"
    else
        print_status "warning" "AWX web pods taking longer than expected"
    fi
    
    if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-task -n "$AWX_NAMESPACE" --timeout=180s > /dev/null 2>&1; then
        print_status "success" "AWX task pods are ready"
    else
        print_status "warning" "AWX task pods taking longer than expected"
    fi
    
    print_status "success" "Restoration verification completed"
}

# Main restore function
main() {
    print_header
    
    print_status "info" "Starting AWX data restoration process..."
    echo ""
    
    list_backups
    echo ""
    
    select_backup "$1"
    echo ""
    
    print_status "warning" "⚠️  IMPORTANT WARNINGS:"
    echo "   • This will OVERWRITE current AWX data"
    echo "   • Current inventories, projects, and jobs will be REPLACED"
    echo "   • Make sure you have a backup of current data if needed"
    echo ""
    
    read -p "Continue with restoration? Type 'RESTORE' to confirm: " -r confirm
    echo ""
    
    if [[ "$confirm" != "RESTORE" ]]; then
        print_status "info" "Restoration cancelled"
        exit 0
    fi
    
    check_prerequisites
    echo ""
    
    # Execute restore steps
    restore_database
    echo ""
    
    restore_files
    echo ""
    
    verify_restore
    echo ""
    
    echo "═══════════════════════════════════════════════════════════════════════════════"
    print_status "success" "🎉 AWX restoration completed!"
    echo ""
    echo "📊 Restoration Summary:"
    echo "   🗃️  Database: Restored from backup"
    echo "   📁 Files: Restored projects and configurations"
    echo "   🔄 Pods: Restarted to apply changes"
    echo ""
    echo "🌐 Access your restored AWX:"
    echo "   Portal: http://localhost:9080 (after port-forward setup)"
    echo "   Use: ./scripts/cluster-manager.sh access"
    echo ""
    echo "🔍 Check restoration status:"
    echo "   ./scripts/cluster-manager.sh health"
    echo ""
    print_status "info" "Your AWX data has been restored from: $SELECTED_BACKUP"
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# Show usage if no arguments provided and not interactive
if [ $# -eq 0 ] && [ ! -t 0 ]; then
    echo "Usage: $0 [backup_timestamp]"
    echo ""
    echo "Examples:"
    echo "  $0                     # Interactive mode - shows available backups"
    echo "  $0 20241126_143022     # Restore specific backup by timestamp"
    exit 0
fi

# Run main function
main "$@"
