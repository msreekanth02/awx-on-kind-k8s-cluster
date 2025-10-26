#!/bin/bash

# AWX Backup Script
# This script creates a backup of your AWX deployment

BACKUP_DIR="/tmp/awx-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

echo "=== AWX Backup Script ==="
echo "Backup directory: $BACKUP_DIR"
echo ""

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to cluster"
    exit 1
fi

echo "1. Backing up AWX configuration..."
kubectl get awx -n awx -o yaml > $BACKUP_DIR/awx-instance.yaml
echo "✅ AWX instance configuration saved"

echo ""
echo "2. Backing up secrets..."
kubectl get secrets -n awx -o yaml > $BACKUP_DIR/secrets.yaml
echo "✅ Secrets saved"

echo ""
echo "3. Backing up persistent volumes..."
kubectl get pv -o yaml > $BACKUP_DIR/persistent-volumes.yaml
kubectl get pvc -n awx -o yaml > $BACKUP_DIR/persistent-volume-claims.yaml
echo "✅ Storage configuration saved"

echo ""
echo "4. Backing up ConfigMaps..."
kubectl get configmaps -n awx -o yaml > $BACKUP_DIR/configmaps.yaml
echo "✅ ConfigMaps saved"

echo ""
echo "5. Backing up Services..."
kubectl get services -n awx -o yaml > $BACKUP_DIR/services.yaml
echo "✅ Services saved"

echo ""
echo "6. Backing up Ingress..."
kubectl get ingress -n awx -o yaml > $BACKUP_DIR/ingress.yaml 2>/dev/null || echo "⚠️  No ingress found"

echo ""
echo "7. Saving cluster information..."
kubectl cluster-info > $BACKUP_DIR/cluster-info.txt
kubectl get nodes -o wide > $BACKUP_DIR/nodes.txt
kubectl version > $BACKUP_DIR/version.txt

echo ""
echo "8. Creating database backup (if accessible)..."
if kubectl get pod -n awx -l app.kubernetes.io/name=postgres --no-headers 2>/dev/null | grep -q Running; then
    echo "Attempting database backup..."
    kubectl exec -n awx deployment/awx-postgres -- pg_dump -U awx awx > $BACKUP_DIR/database-backup.sql 2>/dev/null && echo "✅ Database backup completed" || echo "⚠️  Database backup failed"
else
    echo "⚠️  PostgreSQL pod not found or not running"
fi

echo ""
echo "9. Creating backup manifest..."
cat > $BACKUP_DIR/backup-manifest.txt << EOF
AWX Backup Manifest
===================
Date: $(date)
Cluster: $(kubectl config current-context)
AWX Version: $(kubectl get awx awx -n awx -o jsonpath='{.status.version}' 2>/dev/null || echo "Unknown")
Operator Version: $(kubectl get deployment awx-operator-controller-manager -n awx-operator-system -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Unknown")

Contents:
- awx-instance.yaml: AWX instance configuration
- secrets.yaml: All secrets in AWX namespace
- persistent-volumes.yaml: Persistent volume definitions
- persistent-volume-claims.yaml: PVC definitions
- configmaps.yaml: ConfigMaps in AWX namespace
- services.yaml: Services in AWX namespace
- ingress.yaml: Ingress configurations
- cluster-info.txt: Cluster information
- nodes.txt: Node information
- version.txt: Kubernetes version
- database-backup.sql: PostgreSQL database dump (if successful)

Restore Instructions:
1. Create new kind cluster with same configuration
2. Install AWX operator
3. Apply configurations in this order:
   - kubectl apply -f persistent-volumes.yaml
   - kubectl create namespace awx
   - kubectl apply -f secrets.yaml
   - kubectl apply -f configmaps.yaml
   - kubectl apply -f awx-instance.yaml
4. Wait for deployment to complete
5. Restore database if needed
EOF

echo ""
echo "=== Backup Complete ==="
echo "Backup location: $BACKUP_DIR"
echo ""
echo "📋 Backup contents:"
ls -la $BACKUP_DIR
echo ""
echo "💡 To restore, follow instructions in: $BACKUP_DIR/backup-manifest.txt"
