# AWX on Kind Kubernetes Cluster

**Enterprise-grade AWX deployment with complete lifecycle management, backup/restore capabilities, and reliable network access.**

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![AWX](https://img.shields.io/badge/AWX-EE0000?style=flat&logo=ansible&logoColor=white)](https://github.com/ansible/awx)
[![Kind](https://img.shields.io/badge/Kind-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kind.sigs.k8s.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🎯 Features

- **🚀 One-Click Deployment**: Complete AWX setup with a single command
- **💾 Enterprise Backup/Restore**: Full database and configuration backup system with menu integration
- **🌐 Permanent Port Access**: localhost:8082, host IP:8082, and nip.io:8082 (NO port forwarding required)
- **🔄 Complete Lifecycle Management**: Deploy, stop, start, destroy with guaranteed consistency
- **📊 Real-time Status Monitoring**: Comprehensive health checks and diagnostics
- **🛠️ Interactive Management**: User-friendly menu system for all operations
- **🏗️ Predictable Infrastructure**: Same cluster names, pod names, and ports every time
- **🔒 Data Durability**: Tested zero-loss backup/restore across complete cluster destruction

---

## 📋 Quick Start

### Prerequisites

- **Docker Desktop** or **Docker Engine** (running)
- **Kind** (Kubernetes in Docker) - [Installation Guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- **kubectl** (Kubernetes CLI) - [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **curl** (for connectivity tests)
- **macOS/Linux** (Windows support via WSL2)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd awx-on-kind-k8s-cluster
   ```

2. **Launch the control center (RECOMMENDED):**
   ```bash
   ./awx-manager.sh
   ```
   
   **OR for quick deployment without menu:**
   ```bash
   ./scripts/quick-deploy.sh
   ```

### Getting Started

🎯 **For the best experience, use the integrated control center:**

```bash
./awx-manager.sh
```

This provides a complete menu-driven interface for all operations including:
- ✅ Cluster deployment with consistent configuration
- ✅ Real-time status monitoring
- ✅ Backup and restore operations
- ✅ Network access management
- ✅ Safe cluster destruction

---

## 🎛️ Control Center

The main control interface (`awx-manager.sh`) provides a comprehensive menu system:

```
╔══════════════════════════════════════════════════════════════════╗
║                   AWX ON KIND KUBERNETES CLUSTER                 ║
║                  Enterprise-Grade Control Center                 ║
╚══════════════════════════════════════════════════════════════════╝

🎛️  Main Menu
═══════════
1. 📊 Cluster Status
2. 🚀 Deploy AWX Cluster
3. ⏹️  Stop Cluster
4. ▶️  Start Cluster
5. 💥 Destroy Cluster
6. 💾 Create Backup
7. 🔄 Restore from Backup
8. 📋 List Backups
9. 🌐 Network & Access Tools
0. 🚪 Exit
```

### Menu Functions

| Option | Function | Description |
|--------|----------|-------------|
| **1** | Cluster Status | Real-time health check of all components |
| **2** | Deploy AWX Cluster | Complete deployment with permanent port configuration |
| **3** | Stop Cluster | Stop cluster while preserving all data |
| **4** | Start Cluster | Start stopped cluster with preserved state |
| **5** | Destroy Cluster | Safe cluster destruction with confirmation |
| **6** | Create Backup | Full database and configuration backup |
| **7** | Restore from Backup | Interactive restoration from available backups |
| **8** | List Backups | View all available backups with details |
| **9** | Network & Access Tools | Port status and connectivity management |

---

## 🌐 Network Access

### Permanent Port Configuration (NO Port Forwarding Required!)

After deployment, AWX is accessible via **permanent NodePort mapping** (30080 → 8082):

- **🏠 Local Access**: `http://localhost:8082`
- **🌍 Host IP Access**: `http://192.168.1.243:8082`
- **🌐 nip.io Domain**: `http://awx-192-168-1-243.nip.io:8082`

✅ **Major Advantage**: No manual port forwarding required! Ports work automatically across cluster restarts.

### Default Credentials

- **Username**: `admin`
- **Password**: `password`

### Network Tools Menu

Access the network tools submenu (option 9) for:
- View permanent port mapping status
- Test portal connectivity
- Show all access URLs
- Port status verification
- Network diagnostics

---

## 💾 Backup & Restore System

### Enterprise-Grade Data Protection

#### Automatic Backup Creation
- **Location**: `~/awx-backups/`
- **Format**: Timestamped directories (`YYYYMMDD_HHMMSS`)
- **Contents**: Database dump, Kubernetes resources, metadata
- **Git-Safe**: Backups stored outside project directory

#### What Gets Backed Up
- **Database**: Complete PostgreSQL dump with all user data
- **Kubernetes Resources**: All AWX-related configurations
- **Secrets**: Encrypted password and configuration data
- **ConfigMaps**: Application configurations
- **Metadata**: Backup information and cluster details

#### Backup Structure
```
~/awx-backups/
├── 20241126_120310/
│   ├── database/
│   │   └── awx_full_backup.sql
│   ├── kubernetes/
│   │   ├── awx_resources.yaml
│   │   ├── awx_secrets.yaml
│   │   └── awx_configmaps.yaml
│   └── metadata/
│       └── backup_info.yaml
└── 20241126_134522/
    └── ...
```

### Restore Process

1. **Interactive Selection**: Choose from available backups
2. **Safety Confirmation**: Warns about data replacement
3. **Service Management**: Automatically stops/starts services
4. **Data Integrity**: Ensures complete database restoration
5. **Verification**: Confirms successful restoration

### Zero-Loss Restoration

The backup/restore system has been tested through complete cluster lifecycle:
- ✅ Create backup with user data
- ✅ Destroy entire cluster
- ✅ Recreate cluster from scratch
- ✅ Restore all data with zero loss
- ✅ Verify all users, inventories, and configurations

---

## 🏗️ Infrastructure Details

### Cluster Architecture

- **Type**: Kind (Kubernetes in Docker)
- **Nodes**: 3 nodes (1 control-plane, 2 workers)
- **Kubernetes Version**: Latest stable
- **AWX Operator**: Latest stable (installed via kustomize)
- **AWX Version**: Latest stable (v24.6.1)
- **Database**: PostgreSQL 15 with persistent storage
- **Port Configuration**: NodePort 30080 → Host 8082 (permanent mapping)

### Consistent Configuration

#### Fixed Naming Convention
- **Cluster Name**: `awx-cluster` (never changes)
- **Namespace**: `awx`
- **AWX Instance**: `awx`
- **Database**: `awx`
- **Service Port**: `8082` (permanent NodePort mapping)
- **Internal NodePort**: `30080` (Kubernetes internal)

#### Pod Naming Consistency
```
awx-operator-controller-manager-*
awx-postgres-15-0
awx-web-*
awx-task-*
awx-migration-*
```

### Network Configuration

- **Service Type**: NodePort
- **Permanent Port Mapping**: NodePort 30080 → Host 8082
- **Kind Cluster Config**: Automatic port mapping on cluster creation
- **Access Methods**: localhost, host IP, and nip.io (all on port 8082)
- **NO Port Forwarding**: Permanent configuration eliminates manual port forwarding

---

## 📁 Project Structure

```
awx-on-kind-k8s-cluster/
├── 📄 README.md                     # This comprehensive guide
├── 🎛️  awx-manager.sh               # Main control center (START HERE)
├── ⚙️  resources/                   # Kubernetes configurations
│   ├── awx-instance-simple.yaml    # AWX deployment with permanent port config
│   └── kind-cluster-config.yaml    # Kind cluster with NodePort mapping
└── 🛠️  scripts/                    # Essential utility scripts
    ├── backup-awx-data.sh           # Create backups
    ├── restore-awx-data.sh          # Restore from backups
    ├── quick-deploy.sh              # One-click deployment (port 8082)
    ├── final-status.sh              # Comprehensive status check
    ├── cluster-manager.sh           # Core cluster operations
    └── cleanup.sh                   # Cleanup utilities
```

### Essential Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `awx-manager.sh` | **Main control interface** | `./awx-manager.sh` |
| `scripts/quick-deploy.sh` | Rapid deployment (port 8082) | `./scripts/quick-deploy.sh` |
| `scripts/backup-awx-data.sh` | Create backups | Integrated in control center |
| `scripts/restore-awx-data.sh` | Restore from backup | Integrated in control center |
| `scripts/cluster-manager.sh` | Core cluster operations | Used by control center |
| `scripts/final-status.sh` | Comprehensive status | `./scripts/final-status.sh` |
| `scripts/cleanup.sh` | Clean up resources | `./scripts/cleanup.sh` |

---

## 🔧 Advanced Usage

### Manual Operations

#### Deploy Cluster (Command Line)
```bash
# Create cluster with permanent port mapping
kind create cluster --config=resources/kind-cluster-config.yaml --name=awx-cluster

# Deploy AWX operator
kubectl apply -k https://github.com/ansible/awx-operator/config/default/

# Create namespace and deploy AWX
kubectl create namespace awx
kubectl apply -f resources/awx-instance-simple.yaml

# No port forwarding needed - permanent NodePort mapping active!
# Access at: http://localhost:8082
```

#### Create Backup (Command Line)
```bash
./scripts/backup-awx-data.sh
```

#### Restore from Backup (Command Line)
```bash
./scripts/restore-awx-data.sh
```

#### Monitor Cluster Status
```bash
./final-status.sh
```

### Kubernetes Management

```bash
# View all AWX pods
kubectl get pods -n awx

# Check AWX logs
kubectl logs -n awx deployment/awx-web
kubectl logs -n awx deployment/awx-task

# Scale services
kubectl scale deployment awx-web awx-task -n awx --replicas=0  # Stop
kubectl scale deployment awx-web awx-task -n awx --replicas=1  # Start

# Access database directly
kubectl exec -it awx-postgres-15-0 -n awx -- psql -U awx

# Check permanent port mapping (no manual port forwarding needed)
kubectl get svc -n awx
```

---

## 🚀 Production Readiness

### Tested Scenarios

- ✅ **Complete Lifecycle**: Deploy → Use → Backup → Destroy → Recreate → Restore
- ✅ **Data Durability**: Zero-loss backup and restoration
- ✅ **Network Reliability**: Consistent access across deployments
- ✅ **Service Resilience**: Automatic recovery and health monitoring
- ✅ **Multi-Environment**: Development, testing, and production workflows

### Reliability Features

- **Consistent Configuration**: Same ports, names, and structure every time
- **Safe Operations**: Confirmation prompts for destructive actions
- **Error Handling**: Graceful failure handling and recovery
- **Status Monitoring**: Real-time health checks and diagnostics
- **Backup Validation**: Integrity verification for all backups

### Security Considerations

- **External Backups**: Data stored outside git repository
- **Credential Management**: Configurable admin passwords
- **Network Isolation**: Kubernetes namespace separation
- **Access Control**: Standard AWX RBAC system

---

## 🛠️ Troubleshooting

### Common Issues

#### AWX Not Accessible
```bash
# Check permanent port mapping status
kubectl get svc -n awx

# Verify NodePort service
kubectl get svc awx-service -n awx -o wide

# Test connectivity
curl -s -o /dev/null -w "%{http_code}" http://localhost:8082
```

#### Cluster Won't Start
```bash
# Check Docker
docker ps

# Verify Kind cluster
kind get clusters

# Check cluster status
kubectl get nodes

# View events
kubectl get events -n awx
```

#### Database Issues
```bash
# Check database pod
kubectl get pods -n awx | grep postgres

# View database logs
kubectl logs awx-postgres-15-0 -n awx

# Test database connection
kubectl exec -it awx-postgres-15-0 -n awx -- psql -U awx -c "SELECT 1;"
```

#### AWX Pods Not Starting
```bash
# Check pod status
kubectl describe pod -n awx <pod-name>

# View operator logs
kubectl logs -n awx deployment/awx-operator-controller-manager

# Check resource usage
kubectl top pods -n awx
```

### Reset Everything

If you encounter persistent issues:

```bash
# Complete reset
kind delete cluster --name=awx-cluster
docker system prune -f
./awx-manager.sh  # Redeploy
```

---

## ✨ Recent Improvements & Cleanup

### 🧹 **Repository Streamlining (November 2024)**

The repository has been completely cleaned up and streamlined for maximum reliability:

#### **What Was Removed**
- ❌ **15+ duplicate files** with redundant functionality
- ❌ **Multiple conflicting resource configurations**
- ❌ **Scattered documentation** across multiple files
- ❌ **Manual port forwarding requirements**
- ❌ **Inconsistent Docker stop commands** causing issues

#### **What Was Enhanced**
- ✅ **Single entry point**: `./awx-manager.sh` (main control center with 9 options)
- ✅ **Permanent port mapping**: NodePort 30080 → Host 8082 (NO port forwarding needed!)
- ✅ **Enhanced menu system**: Added Stop/Start cluster options (options 3 & 4)
- ✅ **Fixed Docker issues**: Removed problematic Docker quit commands
- ✅ **Updated AWX operator**: Fixed broken URL, now using kustomize method
- ✅ **Database backup/restore**: Fully integrated menu-driven data protection

#### **Major Technical Improvements**
- 🔧 **Permanent Port Solution**: Configured `nodeport_port: 30080` in AWX instance
- 🔧 **Kind Cluster Enhancement**: Added port mapping `containerPort: 30080` → `hostPort: 8082`
- 🔧 **Zero Port Forwarding**: Eliminated need for manual `kubectl port-forward`
- 🔧 **Docker Stability**: Fixed cluster operations without stopping Docker Desktop
- 🔧 **Operator Installation**: Updated from broken URL to `kubectl apply -k` method
- 🔧 **Configuration Fixes**: Corrected `admin_password_secret` field name

#### **Reliability Guarantees**
- 🔒 **Consistent configuration**: Same setup across all deployments
- 🔒 **Predictable pod names**: Never changes between cluster recreations
- 🔒 **Fixed port allocation**: Always 8082, no conflicts or manual setup
- 🔒 **Zero-loss data protection**: Tested backup/restore across full lifecycle
- 🔒 **Three-method access**: localhost, host IP, and nip.io always work automatically
- 🔒 **Cluster lifecycle**: Deploy → Stop → Start → Destroy all work flawlessly

### 🎯 **Quick Start (New Users)**

```bash
# Clone and start immediately
git clone <repo-url>
cd awx-on-kind-k8s-cluster
./awx-manager.sh
```

**That's it!** The control center handles everything else, including:
- ✅ **Automatic deployment** with permanent port 8082
- ✅ **No manual port forwarding** required
- ✅ **Immediate access** at http://localhost:8082
- ✅ **Persistent across restarts** - ports survive cluster lifecycle

### 🚀 **Permanent Port Benefits**

The new permanent port configuration provides significant advantages:

1. **🔄 Survives Cluster Restarts**: Port 8082 works immediately after cluster start/restart
2. **🚫 No Manual Setup**: Zero `kubectl port-forward` commands needed
3. **⚡ Instant Access**: AWX available immediately after deployment completes
4. **🔒 Reliable**: Same port (8082) guaranteed across all cluster operations
5. **🌐 Multi-Access**: Works for localhost, host IP, and nip.io simultaneously

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

### Development Guidelines

- Test all lifecycle operations
- Maintain backward compatibility
- Update documentation for changes
- Follow existing code style
- Validate backup/restore functionality

---

## 🆘 Support

For issues, questions, or contributions:

- 🐛 **Issues**: [GitHub Issues](link-to-issues)
- 💬 **Discussions**: [GitHub Discussions](link-to-discussions)
- 📚 **Documentation**: This comprehensive README

---

**🏆 Enterprise-grade AWX deployment made simple and reliable!**

*Ready to automate your infrastructure? Start with `./awx-manager.sh` and experience AWX on Kubernetes with permanent ports - no manual setup required!*
