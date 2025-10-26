# AWX Operator on Kind Kubernetes Cluster

A comprehensive, user-friendly solution to deploy AWX (Ansible Tower Community Edition) using the AWX Operator on a local Kind Kubernetes cluster. Features an **interactive menu system** for effortless management, self-healing capabilities, and automated troubleshooting.

## 🌟 Key Features

- **🎮 Interactive Management Console**: Color-coded, menu-driven interface for all operations
- **🧠 Smart Automation**: Intelligent conflict detection, auto-recovery, and guided workflows
- **🔄 Self-Healing Infrastructure**: Automatic recovery from failures with multiple replicas
- **🌐 User-Friendly Access**: Full web UI accessible via localhost (no port conflicts)
- **💾 Persistent Data Storage**: Data survives container restarts and system reboots
- **🛡️ Secure by Default**: Uses secure port-forwarding without exposing host ports
- **🔧 Built-in Diagnostics**: 21-point health checks with automated troubleshooting
- **📊 Real-time Monitoring**: Live status dashboards and resource monitoring
- **💾 Backup & Restore**: Automated backup solutions with timestamped archives
- **📚 Comprehensive Documentation**: Multiple guides for different skill levels

## 🎯 Interactive Setup (RECOMMENDED)

**The easiest way to get started!** Our interactive setup provides a professional, guided experience:

```bash
# 1. Clone and navigate to the project
git clone <your-repo-url>
cd awx-on-kind-k8s-cluster

# 2. Launch the interactive setup console
./setup.sh
```

### 🎮 What You'll Get
- **📋 Real-time Status Dashboard**: See cluster and AWX status at a glance
- **🎯 Guided Workflows**: Step-by-step processes for every operation
- **🌈 Color-coded Interface**: Easy-to-read status indicators and progress
- **🔧 Built-in Troubleshooting**: Automated problem detection and resolution
- **📚 Integrated Help**: Documentation and guides accessible from the interface
- **⚡ One-click Operations**: Deploy, scale, backup, and monitor with ease

### 🚀 Quick Workflow
```
Interactive Setup Console
├── 1) 🏗️  Create cluster (automated with conflict detection)
├── 2) 🚀 Deploy AWX (progress monitoring and error recovery)
├── 3) 🌐 Start access (automatic port forwarding and credentials)
├── 5) 📊 View status (real-time monitoring dashboard)
└── ... and much more!
```

**Result**: AWX running at http://localhost:9080 with admin credentials displayed!

## ⚡ Alternative Quick Methods

### For Experienced Users
```bash
# Fully automated deployment
scripts/quick-deploy.sh
```

### For Manual Control
Follow the [Step-by-Step Installation](#step-by-step-installation) guide below.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Interactive Setup Features](#interactive-setup-features)
- [Quick Start Methods](#quick-start-methods)
- [Step-by-Step Installation](#step-by-step-installation)
- [Accessing AWX](#accessing-awx)
- [Configuration](#configuration)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Project Documentation](#project-documentation)

## Prerequisites

Before starting, ensure you have the following tools installed on your macOS system:

### Required Tools

1. **Docker Desktop** (version 4.0+)
   ```bash
   # Install via Homebrew
   brew install --cask docker
   
   # Or download from: https://www.docker.com/products/docker-desktop
   ```

2. **kubectl** (Kubernetes CLI)
   ```bash
   brew install kubectl
   ```

3. **kind** (Kubernetes in Docker)
   ```bash
   brew install kind
   ```

4. **Helm** (Package Manager for Kubernetes)
   ```bash
   brew install helm
   ```

### System Requirements

- **macOS**: 10.15+ (Catalina or later)
- **RAM**: Minimum 8GB (16GB recommended)
- **CPU**: 4+ cores
- **Disk Space**: 20GB+ available
- **Docker**: Running and accessible

### Verification

Verify all tools are properly installed:

```bash
# Check Docker
docker --version

# Check kubectl
kubectl version --client

# Check kind
kind version

# Check Helm
helm version
```

## 🎮 Interactive Setup Features

Our **interactive setup console** (`setup.sh`) provides a comprehensive, user-friendly interface for managing your AWX deployment. It's designed to make complex Kubernetes operations accessible to users of all skill levels.

### 🌟 Main Features

#### 📊 Real-Time Status Dashboard
```
📊 Current Status
═══════════════
🏗️  Kind Cluster: ✅ Running
🔧 AWX Instance: ✅ Running  
🌐 Port Forward: ✅ Active (http://localhost:9080)

📈 Resource Usage
═════════════════
🐳 Docker Containers: 3 running
🚀 Kubernetes Pods: 12 running
```

#### 🎯 Comprehensive Menu System

**🏗️ Cluster Management**
- Create/destroy Kind clusters with conflict detection
- Start/stop/restart cluster services
- View cluster information and health
- Intelligent storage and networking setup

**⚙️ AWX Operations**
- Full AWX deployment with progress monitoring  
- Quick deployment options for experienced users
- Port forwarding management with status tracking
- Admin credential retrieval and browser integration
- Scaling and update capabilities

**🔧 Maintenance & Tools**
- Docker resource cleanup and optimization
- Port conflict detection and resolution
- Automated backup creation with timestamps
- Resource usage monitoring and reporting
- System maintenance and health optimization

**🩺 Monitoring & Diagnostics**
- 21-point comprehensive health checks
- Deployment verification with detailed status
- Real-time log viewing for all components
- Kubernetes event monitoring and analysis
- Guided troubleshooting with automated fixes

**📚 Documentation & Help**
- Integrated access to all project documentation
- Interactive troubleshooting guides
- Command reference and best practices
- Direct links to official AWX resources

### 🎨 User Experience Highlights

- **🌈 Color-Coded Interface**: Red for errors, green for success, yellow for warnings, blue for info
- **🔄 Smart Automation**: Automatic prerequisite checking, conflict detection, and error recovery
- **📱 Responsive Design**: Adapts to terminal size with consistent formatting
- **🎯 Context-Aware Menus**: Options change based on current system state
- **💡 Helpful Guidance**: Built-in tips, warnings, and next-step suggestions
- **⚡ Quick Operations**: Common tasks accessible with just a few clicks

### 🚀 Getting Started with Interactive Setup

```bash
# 1. Launch the console
./setup.sh

# 2. Follow the guided workflow:
#    ├── Check prerequisites (Option 10)
#    ├── Create cluster (Option 1)
#    ├── Deploy AWX (Option 2) 
#    ├── Start access (Option 3)
#    └── Monitor status (Option 5)

# 3. Access AWX at http://localhost:9080
#    Credentials displayed automatically!
```

**💡 Pro Tip**: The interactive setup is perfect for learning AWX and Kubernetes concepts while providing a production-ready deployment.

## Quick Start Methods

### 🎯 Interactive Setup (Recommended)

For the best user experience, use our interactive setup script:

```bash
# Clone and navigate to the project
git clone <your-repo-url>
cd awx-on-kind-k8s-cluster

# Run the interactive setup
./setup.sh
```

The interactive setup provides:
- ✅ **User-friendly menu system**
- ✅ **Step-by-step guidance**
- ✅ **Real-time status monitoring**
- ✅ **Built-in troubleshooting**
- ✅ **Automated error handling**
- ✅ **One-click operations**

### ⚡ Automated Quick Deploy

For experienced users who prefer automation:

```bash
# Alternative: Automated deployment
scripts/quick-deploy.sh

# Manual step-by-step (if you prefer manual control):
# Create kind cluster
kind create cluster --config=resources/kind-cluster-config.yaml --name=awx-cluster

# Install AWX Operator
kubectl apply -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1

# Deploy AWX instance
kubectl apply -f resources/awx-instance.yaml

# Wait for deployment (5-10 minutes)
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx --timeout=600s

# Get admin password
kubectl get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode

# Port forward (in separate terminal)
kubectl port-forward service/awx-service 9080:80

# Access: http://localhost:9080
# Username: admin
# Password: <output from above command>
```

## 🛠️ Available Tools

This project includes several utility scripts for easy management:

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup.sh` | **Interactive menu system** | `scripts/setup.sh` |
| `quick-deploy.sh` | Automated deployment | `scripts/quick-deploy.sh` |
| `health-check.sh` | System health monitoring | `scripts/health-check.sh` |
| `verify-deployment.sh` | Complete deployment verification | `scripts/verify-deployment.sh` |
| `access-awx.sh` | Easy access with credentials | `scripts/access-awx.sh` |
| `backup-awx.sh` | Create backups | `scripts/backup-awx.sh` |
| `cleanup.sh` | Clean up resources | `scripts/cleanup.sh` |
| `check-ports.sh` | Check port availability | `scripts/check-ports.sh` |

## Interactive Setup Guide

The `setup.sh` script provides a comprehensive menu-driven interface for managing your AWX deployment. Here's what you can do:

### 🏗️ Cluster Management
- **Create new cluster**: Sets up a Kind cluster with proper configuration
- **Deploy AWX**: Installs AWX Operator and creates AWX instance
- **Start AWX access**: Configures port-forwarding for web access
- **Stop AWX access**: Stops port-forwarding

### 📊 Operations
- **Status dashboard**: Real-time status of cluster and AWX components
- **Update & scale**: Modify resource limits and replica counts
- **Backup & restore**: Create and manage backups

### 🔧 Maintenance
- **Troubleshooting**: Built-in diagnostics and problem resolution
- **Cleanup resources**: Various cleanup options (selective or complete)

### 💡 Features
- **Color-coded output** for easy reading
- **Progress indicators** for long-running operations
- **Error handling** with helpful suggestions
- **Prerequisites checking** before operations
- **Real-time status monitoring**

### Usage Example

```bash
# Start the interactive setup
./setup.sh

# The menu will guide you through:
# 1. Prerequisites check
# 2. Cluster creation
# 3. AWX deployment
# 4. Access configuration
# 5. Ongoing management
```

## Step-by-Step Installation

### Step 1: Create Kind Cluster Configuration

Create a kind cluster configuration file that enables ingress and sets up proper networking:

```bash
cat > kind-cluster-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: awx-cluster
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
  - containerPort: 443
    hostPort: 9443
    protocol: TCP
- role: worker
  extraMounts:
  - hostPath: /tmp/awx-data
    containerPath: /data
- role: worker
  extraMounts:
  - hostPath: /tmp/awx-data
    containerPath: /data
EOF
```

### Step 2: Create the Kind Cluster

```bash
# Create local data directory for persistence
mkdir -p /tmp/awx-data

# Create the kind cluster
kind create cluster --config=kind-cluster-config.yaml --name=awx-cluster

# Create required directories in kind nodes for persistent storage
docker exec awx-cluster-worker mkdir -p /data/postgres /data/projects 2>/dev/null || true
docker exec awx-cluster-worker2 mkdir -p /data/postgres /data/projects 2>/dev/null || true

# Verify cluster is running
kubectl cluster-info --context kind-awx-cluster
kubectl get nodes
```

### Step 3: Install NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### Step 4: Create AWX Namespace and Storage

```bash
# Create AWX namespace
kubectl create namespace awx

# Create persistent volume for AWX data
cat > awx-pv.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: awx-postgres-volume
  namespace: awx
spec:
  capacity:
    storage: 8Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /data/postgres
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: awx-projects-volume
  namespace: awx
spec:
  capacity:
    storage: 8Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /data/projects
EOF

kubectl apply -f resources/awx-pv.yaml
```

### Step 5: Install AWX Operator

```bash
# Install the latest AWX Operator (version 2.19.1 as of October 2025)
kubectl apply -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1

# Verify operator installation
kubectl get deployment -n awx-operator-system awx-operator-controller-manager 2>/dev/null || \
kubectl get deployment -n awx awx-operator-controller-manager

# Wait for operator to be ready
if kubectl get deployment awx-operator-controller-manager -n awx-operator-system >/dev/null 2>&1; then
  kubectl wait --for=condition=available deployment/awx-operator-controller-manager \
    -n awx-operator-system --timeout=300s
elif kubectl get deployment awx-operator-controller-manager -n awx >/dev/null 2>&1; then
  kubectl wait --for=condition=available deployment/awx-operator-controller-manager \
    -n awx --timeout=300s
else
  echo "AWX Operator not found. Installation may have failed."
  exit 1
fi
```

### Step 6: Deploy AWX Instance

Create the AWX instance configuration:

```bash
cat > awx-instance.yaml << 'EOF'
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: ClusterIP
  ingress_type: ingress
  ingress_class_name: nginx
  hostname: awx.local
  
  # Resource specifications for performance and self-healing
  web_resource_requirements:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  task_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
  
  ee_resource_requirements:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1000m
      memory: 2Gi
  
  # PostgreSQL configuration
  postgres_configuration_secret: awx-postgres-configuration
  postgres_storage_class: standard
  postgres_storage_requirements:
    requests:
      storage: 8Gi
  
  # Projects storage
  projects_persistence: true
  projects_storage_class: standard
  projects_storage_size: 8Gi
  projects_storage_access_mode: ReadWriteOnce
  
  # Auto-scaling and self-healing
  replicas: 1
  web_replicas: 2
  task_replicas: 2
  
  # Security context
  security_context_settings:
    runAsUser: 1000
    runAsGroup: 0
    fsGroup: 0
    fsGroupChangePolicy: OnRootMismatch
  
  # Additional configurations for stability
  extra_settings:
    - setting: INSIGHTS_TRACKING_STATE
      value: "False"
    - setting: AUTOMATION_ANALYTICS_GATHER_INTERVAL
      value: "0"
EOF

# Create PostgreSQL configuration secret
kubectl create secret generic awx-postgres-configuration \
  --from-literal=host=awx-postgres \
  --from-literal=port=5432 \
  --from-literal=database=awx \
  --from-literal=username=awx \
  --from-literal=password=awxpass123 \
  --from-literal=type=managed \
  -n awx

# Deploy AWX instance
kubectl apply -f resources/awx-instance.yaml
```

### Step 7: Monitor Deployment

```bash
# Watch the deployment progress
kubectl get pods -n awx --watch

# Check AWX instance status
kubectl get awx -n awx

# View logs if needed
kubectl logs -f deployment/awx-operator-controller-manager -n awx-operator-system 2>/dev/null || \
kubectl logs -f deployment/awx-operator-controller-manager -n awx

# Wait for all pods to be ready (this may take 5-10 minutes)
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx -n awx --timeout=600s
```

## Accessing AWX

### Method 1: Port Forwarding (Recommended)

```bash
# Forward AWX service to localhost
kubectl port-forward service/awx-service 9080:80 -n awx

# In another terminal, you can also forward the PostgreSQL if needed
kubectl port-forward service/awx-postgres 5432:5432 -n awx
```

### Method 2: Using Ingress (Alternative)

```bash
# Add entry to /etc/hosts
echo "127.0.0.1 awx.local" | sudo tee -a /etc/hosts

# Access via: http://awx.local:9080
```

### Getting Admin Credentials

```bash
# Get the admin password
kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode
echo  # for newline

# Username is always: admin
```

### Access URLs

- **AWX Web Interface**: `http://localhost:9080`
- **Username**: `admin`
- **Password**: (obtained from the command above)

## Configuration

### Self-Healing Configuration

The cluster includes several self-healing mechanisms:

1. **Pod Restart Policies**: Automatic restart on failure
2. **Resource Limits**: Prevent resource exhaustion
3. **Health Checks**: Liveness and readiness probes
4. **Persistent Storage**: Data survives pod restarts
5. **Multiple Replicas**: High availability for critical components

### User Interaction Features

1. **Web Interface**: Full AWX web UI accessible via browser
2. **API Access**: RESTful API for automation
3. **CLI Tools**: Ansible and AWX CLI integration
4. **Job Templates**: Pre-configured automation templates
5. **Inventory Management**: Dynamic inventory sources

### Performance Tuning

Edit the AWX instance for better performance:

```bash
# Scale up replicas for high availability
kubectl patch awx awx -n awx --type='merge' -p='{"spec":{"web_replicas":3,"task_replicas":3}}'

# Update resource limits
kubectl patch awx awx -n awx --type='merge' -p='{"spec":{"web_resource_requirements":{"limits":{"cpu":"4000m","memory":"8Gi"}}}}'
```

### Backup Configuration

```bash
# Create backup script
cat > backup-awx.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/tmp/awx-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup AWX configuration
kubectl get awx -n awx -o yaml > $BACKUP_DIR/awx-instance.yaml

# Backup secrets
kubectl get secrets -n awx -o yaml > $BACKUP_DIR/secrets.yaml

# Backup persistent volumes
kubectl get pv -o yaml > $BACKUP_DIR/persistent-volumes.yaml

echo "Backup completed in: $BACKUP_DIR"
EOF

chmod +x backup-awx.sh
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Pods Stuck in Pending State

```bash
# Check node resources
kubectl describe nodes

# Check storage
kubectl get pv,pvc -n awx

# Check events
kubectl get events -n awx --sort-by='.lastTimestamp'
```

#### 2. AWX Not Accessible

```bash
# Check service status
kubectl get svc -n awx

# Check ingress
kubectl get ingress -n awx

# Verify port-forward is running
ps aux | grep "kubectl port-forward"
```

#### 3. Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl logs -l app.kubernetes.io/name=postgres -n awx

# Test database connectivity
kubectl exec -it deployment/awx-web -n awx -- pg_isready -h awx-postgres
```

#### 4. Performance Issues

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n awx

# Scale resources
kubectl patch awx awx -n awx --type='merge' -p='{"spec":{"web_resource_requirements":{"requests":{"cpu":"2000m","memory":"4Gi"}}}}'
```

### Debug Commands

```bash
# Get comprehensive cluster status
kubectl get all -n awx

# Check operator logs
kubectl logs -f deployment/awx-operator-controller-manager -n awx-operator-system 2>/dev/null || \
kubectl logs -f deployment/awx-operator-controller-manager -n awx

# Describe AWX instance
kubectl describe awx awx -n awx

# Check resource consumption
kubectl top pods -n awx --containers
```

### Health Checks

```bash
# Create health check script
cat > health-check.sh << 'EOF'
#!/bin/bash
echo "=== AWX Health Check ==="

echo "1. Checking cluster status..."
kubectl cluster-info

echo "2. Checking AWX namespace pods..."
kubectl get pods -n awx

echo "3. Checking AWX instance status..."
kubectl get awx -n awx

echo "4. Checking services..."
kubectl get svc -n awx

echo "5. Checking persistent volumes..."
kubectl get pv

echo "6. Testing AWX API (requires port-forward)..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:9080/api/v2/ping/ || echo "Port-forward not active or AWX not responding"

echo "=== Health Check Complete ==="
EOF

chmod +x health-check.sh
```

## Cleanup

### Remove AWX Instance Only

```bash
# Delete AWX instance (keeps operator and cluster)
kubectl delete awx awx -n awx

# Delete namespace
kubectl delete namespace awx
```

### Complete Cleanup

```bash
# Delete AWX instance
kubectl delete awx awx -n awx

# Delete AWX Operator
kubectl delete -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1

# Delete namespace
kubectl delete namespace awx

# Delete kind cluster
kind delete cluster --name=awx-cluster

# Clean up local data
rm -rf /tmp/awx-data
rm -rf /tmp/awx-backup-*

# Remove hosts entry (if added)
sudo sed -i '' '/awx.local/d' /etc/hosts
```

### Selective Cleanup

```bash
# Only restart AWX pods
kubectl rollout restart deployment/awx-web -n awx
kubectl rollout restart deployment/awx-task -n awx

# Reset admin password
kubectl delete secret awx-admin-password -n awx
# Wait for AWX to regenerate the secret
```

## Project Documentation

This project includes comprehensive documentation to support users at all skill levels:

### 📚 Documentation Files

| Document | Purpose | Target Audience |
|----------|---------|-----------------|
| **README.md** | Main installation and usage guide | All users |
| **[INTERACTIVE-FEATURES.md](INTERACTIVE-FEATURES.md)** | Complete guide to interactive setup features | New users, feature overview |
| **[Architecture.md](Architecture.md)** | Technical architecture and system design | Technical users, developers |
| **[GETTING-STARTED.md](GETTING-STARTED.md)** | Beginner-friendly quick start guide | New users, first-time deployments |
| **[PROJECT-STRUCTURE.md](PROJECT-STRUCTURE.md)** | Project organization and file purposes | Developers, contributors |
| **[DEPLOYMENT-SUCCESS.md](DEPLOYMENT-SUCCESS.md)** | Success story and lessons learned | All users, troubleshooting |
| **[PORT-CHANGES.md](PORT-CHANGES.md)** | Port configuration change history | Technical users |

### 🛠️ Script Documentation

| Script | Purpose | Documentation Location |
|--------|---------|----------------------|
| **setup.sh** | Interactive management console | In-script help + [INTERACTIVE-FEATURES.md](INTERACTIVE-FEATURES.md) |
| **quick-deploy.sh** | Automated deployment | In-script comments + README |
| **health-check.sh** | System health verification | In-script help + troubleshooting section |
| **verify-deployment.sh** | Deployment validation | In-script comments + usage examples |
| **backup-awx.sh** | Data backup utility | In-script help + maintenance section |
| **cleanup.sh** | Resource cleanup | In-script options + cleanup section |
| **access-awx.sh** | Access helper | In-script help + access section |
| **check-ports.sh** | Port conflict detection | In-script help + troubleshooting |

### 🎯 Documentation by Use Case

#### 🆕 **New Users**: Start Here!
1. [GETTING-STARTED.md](GETTING-STARTED.md) - Your first AWX deployment
2. [INTERACTIVE-FEATURES.md](INTERACTIVE-FEATURES.md) - Explore all interactive capabilities
3. README.md (this file) - Complete reference

#### 🔧 **Technical Users**: Deep Dive
1. [Architecture.md](Architecture.md) - System architecture and data flow
2. [PROJECT-STRUCTURE.md](PROJECT-STRUCTURE.md) - Project organization
3. Script source code - Implementation details

#### 🐛 **Troubleshooting**: Problem Solving
1. [DEPLOYMENT-SUCCESS.md](DEPLOYMENT-SUCCESS.md) - Known issues and solutions
2. README.md troubleshooting section - Common problems
3. Interactive setup troubleshooting menu (`./setup.sh` → Option 4)

#### 📈 **Advanced Usage**: Optimization
1. [Architecture.md](Architecture.md) - Scaling and performance
2. Script customization - Modify for specific needs
3. Kubernetes documentation - Advanced configuration

### 🚀 Quick Documentation Access

```bash
# Access documentation through interactive setup
./setup.sh
# → Option 5: Documentation & Help

# Direct file access
less README.md
less INTERACTIVE-FEATURES.md
less Architecture.md
less GETTING-STARTED.md

# Online resources
open https://docs.ansible.com/automation-controller/
open https://kind.sigs.k8s.io/
```

### 📝 Documentation Standards

All documentation follows these principles:
- **🎯 User-Focused**: Written for practical use cases
- **📋 Step-by-Step**: Clear, actionable instructions
- **🎨 Visual**: Color-coded, emoji-enhanced for readability
- **🔗 Interconnected**: Cross-referenced for easy navigation
- **✅ Tested**: All instructions verified on real deployments

## Next Steps

After successful deployment, you can:

1. **Configure Authentication**: LDAP, SAML, OAuth
2. **Set Up Inventories**: Dynamic inventories from cloud providers
3. **Create Job Templates**: Automated playbook execution
4. **Configure Notifications**: Email, Slack, webhooks
5. **Set Up Schedules**: Automated job execution
6. **Install Collections**: Additional Ansible content

## Support and Documentation

- **AWX Documentation**: https://docs.ansible.com/automation-controller/
- **AWX Operator**: https://github.com/ansible/awx-operator
- **Kind Documentation**: https://kind.sigs.k8s.io/
- **Kubernetes Documentation**: https://kubernetes.io/docs/

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
