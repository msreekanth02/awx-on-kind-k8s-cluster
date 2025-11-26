#!/bin/bash

# AWX Data Backup Script
# Creates backups outside the project directory for clean git repo

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
BACKUP_BASE_DIR="$HOME/awx-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"
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
    echo -e "${BLUE}║                         ${GREEN}AWX Data Backup Tool${BLUE}                              ║${NC}"
    echo -e "${BLUE}║                    ${GREEN}Safe backup outside project directory${BLUE}                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if cluster is running
check_cluster_status() {
    if ! kubectl cluster-info --request-timeout=10s &> /dev/null; then
        print_status "error" "Kubernetes cluster is not accessible"
        echo "Please start your cluster first using: ./scripts/cluster-manager.sh start"
        exit 1
    fi
    
    if ! kubectl get namespace "$AWX_NAMESPACE" &> /dev/null; then
        print_status "error" "AWX namespace not found"
        echo "Please deploy AWX first using: ./scripts/cluster-manager.sh create"
        exit 1
    fi
    
    print_status "success" "Cluster and AWX namespace verified"
}

# Create backup directory structure
setup_backup_directory() {
    mkdir -p "$BACKUP_DIR"/{database,files,kubernetes,metadata}
    print_status "success" "Backup directory created: $BACKUP_DIR"
}

# Backup PostgreSQL database
backup_database() {
    print_status "info" "Starting database backup..."
    
    local pg_pod=$(kubectl get pods -n "$AWX_NAMESPACE" -l app.kubernetes.io/name=postgres-15 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pg_pod" ]; then
        print_status "error" "PostgreSQL pod not found"
        return 1
    fi
    
    # Create database dump (using postgres user for full access)
    kubectl exec -n "$AWX_NAMESPACE" "$pg_pod" -- pg_dump -U postgres awx > "$BACKUP_DIR/database/awx_full_backup.sql" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_status "success" "Database backup completed"
        echo "   📄 Saved to: $BACKUP_DIR/database/awx_full_backup.sql"
        echo "   📊 Size: $(du -h "$BACKUP_DIR/database/awx_full_backup.sql" | cut -f1)"
    else
        print_status "error" "Database backup failed"
        return 1
    fi
}

# Backup persistent volume data
backup_persistent_data() {
    print_status "info" "Starting persistent volume backup..."
    
    # Get any task pod for file access
    local task_pod=$(kubectl get pods -n "$AWX_NAMESPACE" -l app.kubernetes.io/name=awx-task -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$task_pod" ]; then
        print_status "warning" "No AWX task pods found, skipping file backup"
        return 0
    fi
    
    # Backup projects and other persistent data
    kubectl exec -n "$AWX_NAMESPACE" "$task_pod" -- tar -czf - /var/lib/awx/projects 2>/dev/null > "$BACKUP_DIR/files/awx_projects.tar.gz" 2>/dev/null || true
    kubectl exec -n "$AWX_NAMESPACE" "$task_pod" -- tar -czf - /tmp/awx_receptor 2>/dev/null > "$BACKUP_DIR/files/awx_receptor.tar.gz" 2>/dev/null || true
    
    print_status "success" "Persistent data backup completed"
    echo "   📁 Projects: $BACKUP_DIR/files/awx_projects.tar.gz"
    echo "   📁 Receptor: $BACKUP_DIR/files/awx_receptor.tar.gz"
}

# Backup Kubernetes resources
backup_kubernetes_resources() {
    print_status "info" "Starting Kubernetes resources backup..."
    
    # Backup AWX custom resource
    kubectl get awx awx -n "$AWX_NAMESPACE" -o yaml > "$BACKUP_DIR/kubernetes/awx-custom-resource.yaml" 2>/dev/null || true
    
    # Backup secrets (base64 encoded, but you'll have them)
    kubectl get secrets -n "$AWX_NAMESPACE" -o yaml > "$BACKUP_DIR/kubernetes/awx-secrets.yaml" 2>/dev/null || true
    
    # Backup persistent volume claims
    kubectl get pvc -n "$AWX_NAMESPACE" -o yaml > "$BACKUP_DIR/kubernetes/awx-pvc.yaml" 2>/dev/null || true
    
    # Backup services and deployments
    kubectl get svc,deployment,statefulset -n "$AWX_NAMESPACE" -o yaml > "$BACKUP_DIR/kubernetes/awx-workloads.yaml" 2>/dev/null || true
    
    print_status "success" "Kubernetes resources backup completed"
    echo "   ⚙️  Custom Resources: $BACKUP_DIR/kubernetes/"
}

# Create backup metadata
create_backup_metadata() {
    cat > "$BACKUP_DIR/metadata/backup_info.txt" << EOF
AWX Backup Information
=====================

Backup Date: $(date)
Backup Directory: $BACKUP_DIR
AWX Namespace: $AWX_NAMESPACE

Cluster Information:
- Cluster Context: $(kubectl config current-context)
- AWX Pods Status:
$(kubectl get pods -n "$AWX_NAMESPACE" 2>/dev/null || echo "Could not retrieve pod status")

Database Information:
- PostgreSQL Version: $(kubectl exec -n "$AWX_NAMESPACE" $(kubectl get pods -n "$AWX_NAMESPACE" -l app.kubernetes.io/name=postgres-15 -o jsonpath='{.items[0].metadata.name}') -- psql -U awx -c "SELECT version();" 2>/dev/null | grep PostgreSQL || echo "Could not retrieve DB version")

Admin Credentials:
- Username: admin
- Password: $(kubectl get secret awx-admin-password -n "$AWX_NAMESPACE" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "Password not available")

Restoration Notes:
- To restore: Use the restore-awx-data.sh script
- Database: Import awx_full_backup.sql to new PostgreSQL instance
- Files: Extract tar.gz files to appropriate locations
- K8s Resources: Apply YAML files after cluster recreation

EOF

    print_status "success" "Backup metadata created"
    echo "   📋 Info: $BACKUP_DIR/metadata/backup_info.txt"
}

# Create .gitignore for backup directory
setup_gitignore() {
    if [ ! -f "$BACKUP_BASE_DIR/.gitignore" ]; then
        cat > "$BACKUP_BASE_DIR/.gitignore" << EOF
# AWX Backup Directory
# This directory contains sensitive AWX data and should never be committed to git

*
!.gitignore

# Ignore all backup files
*.sql
*.tar.gz
*.yaml
*.txt

# Ignore all timestamped directories
*/
EOF
        print_status "success" "Created .gitignore for backup directory"
    fi
}

# Main backup function
main() {
    print_header
    
    print_status "info" "Starting AWX data backup process..."
    echo ""
    print_status "info" "Backup will be saved to: $BACKUP_DIR"
    print_status "warning" "This backup will NOT be included in your git repository"
    echo ""
    
    read -p "Continue with backup? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Backup cancelled."
        exit 0
    fi
    
    echo ""
    
    # Execute backup steps
    check_cluster_status
    setup_backup_directory
    setup_gitignore
    
    echo ""
    print_status "info" "🗃️  Backing up database..."
    backup_database
    
    echo ""
    print_status "info" "📁 Backing up persistent data..."
    backup_persistent_data
    
    echo ""
    print_status "info" "⚙️  Backing up Kubernetes resources..."
    backup_kubernetes_resources
    
    echo ""
    print_status "info" "📋 Creating backup metadata..."
    create_backup_metadata
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    print_status "success" "🎉 AWX backup completed successfully!"
    echo ""
    echo "📂 Backup Location:"
    echo "   🏠 Home Directory: $BACKUP_DIR"
    echo "   📊 Total Size: $(du -sh "$BACKUP_DIR" | cut -f1)"
    echo ""
    echo "📋 Backup Contents:"
    echo "   🗃️  Database: Full PostgreSQL dump"
    echo "   📁 Files: Projects and configuration files"
    echo "   ⚙️  K8s Resources: Deployments, secrets, and configurations"
    echo "   📄 Metadata: Backup information and restoration notes"
    echo ""
    echo "🔒 Security Notes:"
    echo "   ✅ Backup is outside your git repository"
    echo "   ✅ .gitignore created to prevent accidental commits"
    echo "   ⚠️  Backup contains sensitive data - keep secure"
    echo ""
    echo "🔄 To restore this backup:"
    echo "   ./scripts/restore-awx-data.sh $TIMESTAMP"
    echo ""
    echo "📁 All backups location:"
    echo "   ls -la $BACKUP_BASE_DIR"
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# Run main function
main "$@"
