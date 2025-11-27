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
- **🌐 Consistent Multi-Access**: localhost:8080, host IP:8080, and nip.io:8080 (always port 8080)
- **🔄 Reliable Lifecycle Management**: Deploy, destroy, and recreate with guaranteed consistency
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
3. 💥 Destroy Cluster
4. 💾 Create Backup
5. 🔄 Restore from Backup
6. 📋 List Backups
7. 🌐 Network & Access Tools
0. 🚪 Exit
```

### Menu Functions

| Option | Function | Description |
|--------|----------|-------------|
| **1** | Cluster Status | Real-time health check of all components |
| **2** | Deploy AWX Cluster | Complete deployment with consistent configuration |
| **3** | Destroy Cluster | Safe cluster destruction with confirmation |
| **4** | Create Backup | Full database and configuration backup |
| **5** | Restore from Backup | Interactive restoration from available backups |
| **6** | List Backups | View all available backups with details |
| **7** | Network & Access Tools | Port forwarding and connectivity management |

---

## 🌐 Network Access

### Automatic Access Configuration

After deployment, AWX is accessible via multiple methods:

- **🏠 Local Access**: `http://localhost:8080`
- **🌍 Host IP Access**: `http://192.168.1.243:8080`
- **🌐 nip.io Domain**: `http://awx-192-168-1-243.nip.io:8080`

### Default Credentials

- **Username**: `admin`
- **Password**: `password`

### Network Tools Menu

Access the network tools submenu (option 7) for:
- Start/Restart port forwarding
- Stop port forwarding
- Show access URLs
- Test portal connectivity

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
- **AWX Operator**: Latest stable (v2.19.1)
- **AWX Version**: Latest stable (v24.6.1)
- **Database**: PostgreSQL 15 with persistent storage

### Consistent Configuration

#### Fixed Naming Convention
- **Cluster Name**: `awx-cluster` (never changes)
- **Namespace**: `awx`
- **AWX Instance**: `awx`
- **Database**: `awx`
- **Service Port**: `8080` (consistent across deployments)

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
- **Port Forwarding**: `8080:80` on all interfaces (`0.0.0.0`)
- **Ingress**: Configured for host IP access
- **nip.io**: Automatic wildcard DNS resolution

---

## 📁 Project Structure

```
awx-on-kind-k8s-cluster/
├── 📄 README.md                     # This comprehensive guide
├── 🎛️  awx-manager.sh               # Main control center (START HERE)
├── ⚙️  resources/                   # Kubernetes configurations
│   ├── awx-instance-simple.yaml    # Simple AWX deployment config
│   └── kind-cluster-config.yaml    # Kind cluster configuration
└── 🛠️  scripts/                    # Essential utility scripts
    ├── backup-awx-data.sh           # Create backups
    ├── restore-awx-data.sh          # Restore from backups
    ├── quick-deploy.sh              # One-click deployment
    ├── final-status.sh              # Comprehensive status check
    └── cleanup.sh                   # Cleanup utilities
```

### Essential Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `awx-manager.sh` | **Main control interface** | `./awx-manager.sh` |
| `scripts/quick-deploy.sh` | Rapid deployment | `./scripts/quick-deploy.sh` |
| `scripts/backup-awx-data.sh` | Create backups | Integrated in control center |
| `scripts/restore-awx-data.sh` | Restore from backup | Integrated in control center |
| `scripts/final-status.sh` | Comprehensive status | `./scripts/final-status.sh` |
| `scripts/cleanup.sh` | Clean up resources | `./scripts/cleanup.sh` |

---

## 🔧 Advanced Usage

### Manual Operations

#### Deploy Cluster (Command Line)
```bash
# Create cluster
kind create cluster --config=resources/kind-cluster-config.yaml --name=awx-cluster

# Deploy AWX
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/devel/deploy/awx-operator.yaml
kubectl create namespace awx
kubectl apply -f resources/awx-instance.yaml

# Start port forwarding
kubectl port-forward svc/awx-service -n awx 8080:80 --address 0.0.0.0 &
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

# Port forward manually
kubectl port-forward svc/awx-service -n awx 8080:80 --address 0.0.0.0
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

#### Port Forwarding Not Working
```bash
# Kill existing processes
pkill -f "kubectl.*port-forward"

# Restart port forwarding
kubectl port-forward svc/awx-service -n awx 8080:80 --address 0.0.0.0 &
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
kubectl logs -n awx-operator-system deployment/awx-operator-controller-manager

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

### 🧹 **Repository Streamlining (November 2025)**

The repository has been completely cleaned up and streamlined for maximum reliability:

#### **What Was Removed**
- ❌ **15+ duplicate files** with redundant functionality
- ❌ **Multiple conflicting resource configurations**
- ❌ **Scattered documentation** across multiple files
- ❌ **Inconsistent port configurations** (9080 vs 8080)
- ❌ **Variable naming** across deployments

#### **What Was Enhanced**
- ✅ **Single entry point**: `./awx-manager.sh` (main control center)
- ✅ **Guaranteed port consistency**: Always 8080 for all access methods
- ✅ **Predictable naming**: Same cluster, namespace, and pod names every time
- ✅ **Integrated backup/restore**: Menu-driven data protection
- ✅ **Complete documentation**: Everything in one comprehensive README

#### **Reliability Guarantees**
- 🔒 **Consistent configuration**: Same setup across all deployments
- 🔒 **Predictable pod names**: Never changes between cluster recreations
- 🔒 **Fixed port allocation**: Always 8080, no conflicts
- 🔒 **Zero-loss data protection**: Tested backup/restore across full lifecycle
- 🔒 **Three-method access**: localhost, host IP, and nip.io always work

### 🎯 **Quick Start (New Users)**

```bash
# Clone and start immediately
git clone <repo-url>
cd awx-on-kind-k8s-cluster
./awx-manager.sh
```

**That's it!** The control center handles everything else.

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

*Ready to automate your infrastructure? Start with `./awx-manager.sh` and experience the power of AWX on Kubernetes!*
