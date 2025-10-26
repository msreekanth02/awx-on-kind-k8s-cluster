#!/bin/bash

# AWX Cleanup Script
# This script removes the AWX deployment and optionally the Kind cluster

echo "=== AWX Cleanup Script ==="
echo ""

# Function to ask for user confirmation
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check what cleanup level to perform
echo "Choose cleanup level:"
echo "1. Remove AWX instance only (keep cluster and operator)"
echo "2. Remove AWX and operator (keep cluster)"
echo "3. Complete cleanup (remove everything including cluster)"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "Option 1: Removing AWX instance only..."
        
        if confirm "Remove AWX instance?"; then
            echo "Removing AWX instance..."
            kubectl delete awx awx -n awx 2>/dev/null || echo "AWX instance not found"
            
            echo "Removing AWX namespace..."
            kubectl delete namespace awx 2>/dev/null || echo "AWX namespace not found"
            
            echo "✅ AWX instance removed. Cluster and operator remain."
        fi
        ;;
        
    2)
        echo ""
        echo "Option 2: Removing AWX and operator..."
        
        if confirm "Remove AWX instance and operator?"; then
            echo "Removing AWX instance..."
            kubectl delete awx awx -n awx 2>/dev/null || echo "AWX instance not found"
            
            echo "Removing AWX namespace..."
            kubectl delete namespace awx 2>/dev/null || echo "AWX namespace not found"
            
            echo "Removing AWX Operator..."
            kubectl delete -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1 2>/dev/null || echo "AWX Operator not found"
            
            echo "Removing operator namespace..."
            kubectl delete namespace awx-operator-system 2>/dev/null || echo "Operator namespace not found"
            
            echo "✅ AWX and operator removed. Cluster remains."
        fi
        ;;
        
    3)
        echo ""
        echo "Option 3: Complete cleanup..."
        
        if confirm "Remove everything including the Kind cluster?"; then
            echo "Removing AWX instance..."
            kubectl delete awx awx -n awx 2>/dev/null || echo "AWX instance not found"
            
            echo "Removing AWX namespace..."
            kubectl delete namespace awx 2>/dev/null || echo "AWX namespace not found"
            
            echo "Removing AWX Operator..."
            kubectl delete -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1 2>/dev/null || echo "AWX Operator not found"
            
            echo "Removing Kind cluster..."
            kind delete cluster --name=awx-cluster 2>/dev/null || echo "Kind cluster not found"
            
            if confirm "Remove local data directory (/tmp/awx-data)?"; then
                echo "Removing local data..."
                rm -rf /tmp/awx-data
                echo "✅ Local data removed"
            fi
            
            if confirm "Remove backup directories (/tmp/awx-backup-*)?"; then
                echo "Removing backup directories..."
                rm -rf /tmp/awx-backup-*
                echo "✅ Backup directories removed"
            fi
            
            # Check for hosts entry
            if grep -q "awx.local" /etc/hosts 2>/dev/null; then
                if confirm "Remove awx.local entry from /etc/hosts?"; then
                    sudo sed -i '' '/awx.local/d' /etc/hosts 2>/dev/null || echo "Could not remove hosts entry"
                    echo "✅ Hosts entry removed"
                fi
            fi
            
            echo "✅ Complete cleanup finished"
        fi
        ;;
        
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Check for running port-forwards
if pgrep -f "kubectl port-forward.*awx" > /dev/null; then
    if confirm "Kill running port-forward processes?"; then
        pkill -f "kubectl port-forward.*awx"
        echo "✅ Port-forward processes terminated"
    fi
fi

echo ""
echo "🧹 Cleanup operations completed!"
echo ""

# Show remaining resources if any
if kubectl config current-context | grep -q "kind-awx-cluster" 2>/dev/null; then
    echo "📊 Remaining resources:"
    echo "Namespaces:"
    kubectl get namespaces | grep -E "(awx|default|kube-)" || echo "None"
    echo ""
    echo "Clusters:"
    kind get clusters || echo "None"
fi

echo "💡 To start fresh, run: ./quick-deploy.sh"
