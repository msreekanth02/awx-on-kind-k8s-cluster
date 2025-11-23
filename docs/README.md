# AWX on Kind Kubernetes Cluster

> 🎮 **Production-Ready Interactive Console** for AWX v24.6.1 on Kind clusters

A streamlined, production-ready solution to deploy **AWX v24.6.1** using the latest **AWX Operator v2.19.1** on a local Kind Kubernetes cluster. Features a comprehensive **menu-driven management system** with real-time monitoring, automated deployment, and simplified maintenance.

## ✨ What's New in This Version

- **✅ Latest Stable Release**: AWX v24.6.1 with Operator v2.19.1
- **🧹 Streamlined Codebase**: Cleaned from 20+ to 8 essential files
- **🎮 Enhanced Menu System**: 13 comprehensive management options
- **🌐 Network Ready**: Configured for host IP access via nip.io
- **📊 Real-time Monitoring**: Live status dashboards and health checks
- **🔄 Self-Healing**: Automatic recovery and scaling capabilities

## 🚀 Quick Start

```bash
# 1. Clone and navigate to the project
git clone <your-repo-url>
cd awx-on-kind-k8s-cluster

# 2. Launch the comprehensive menu system
./scripts/setup.sh

# 3. Follow the guided workflow:
#    - Check prerequisites (option 11)
#    - Create cluster (option 1) 
#    - Deploy AWX v24.6.1 (option 2)
#    - Access portal (option 3)
```

## 📁 Complete Project Structure

```
awx-on-kind-k8s-cluster/              # 🧹 Production-ready repository
├── 📄 setup.sh                       # Quick launcher wrapper
├── 📚 README.md                      # This guide (you are here!)
├── 🏗️ ARCHITECTURE.md               # Visual architecture guide  
├── 🔄 CLUSTER-MANAGEMENT.md          # Complete cluster lifecycle guide
├── 🎉 PRODUCTION-READY.md            # Deployment validation summary
├── 🔧 resources/                     # Kubernetes configurations
│   ├── kind-cluster-config.yaml     # 3-node cluster setup
│   ├── awx-instance.yaml           # AWX v24.6.1 with host IP config
│   └── awx-pv.yaml                 # Persistent storage setup
└── 🎯 scripts/                      # Essential management scripts
    ├── setup.sh                    # 🎮 MAIN: Comprehensive menu system
    ├── cluster-manager.sh          # 🔄 NEW: Complete cluster lifecycle manager  
    ├── access-portal.sh            # Simple portal access
    └── cleanup.sh                  # Resource cleanup
```

## 🎮 Menu System Features

The comprehensive `scripts/setup.sh` provides 13 management options:

### 🏗️ Cluster Management
- **1) Create cluster** - Deploy 3-node Kind cluster with proper networking
- **2) Deploy AWX** - Install AWX v24.6.1 with Operator v2.19.1  
- **3) Start access** - Launch port-forwarding and open browser
- **4) Stop access** - Stop port-forwarding gracefully

### 📊 Operations  
- **5) Status dashboard** - Real-time cluster and AWX monitoring
- **6) Update & scale** - Scale components and update configurations
- **7) Backup & restore** - Data backup and restoration tools
- **8) Complete guide** - Host IP access configuration guide

### 🔧 Maintenance
- **9) Troubleshooting** - Diagnostic tools and log analysis
- **10) Cleanup** - Resource cleanup with confirmation prompts

### ❓ Help & Info
- **11) Prerequisites** - System requirement checks
- **12) Documentation** - View guides and architecture docs  
- **13) Exit** - Clean exit with status summary

## 🔄 **NEW: Complete Cluster Management**

### **Interactive Cluster Manager**
```bash
./scripts/cluster-manager.sh  # Full interactive lifecycle management
```

**🎮 9 Management Options:**
1. **🩺 Health check** - Complete system diagnostics
2. **🔄 Restart cluster** - Restart everything (preserve data)  
3. **🚀 Start cluster** - Resume from stop
4. **🏗️ Create fresh** - Complete rebuild 
5. **💥 Destroy cluster** - Remove everything ⚠️
6. **🌐 Access portal** - Smart portal access
7. **🛑 Stop cluster** - Stop but preserve data
8. **📚 Documentation** - View guides  
9. **❌ Exit** - Clean exit

### **Direct Commands**
```bash
# Health check & diagnostics
./scripts/cluster-manager.sh health

# Restart cluster (preserve data)  
./scripts/cluster-manager.sh restart

# Create fresh cluster
./scripts/cluster-manager.sh create

# Access portal (smart detection)
./scripts/cluster-manager.sh access

# Emergency rebuild
./scripts/cluster-manager.sh destroy
./scripts/cluster-manager.sh create
```

## ⚡ Quick Access Commands

| Purpose | Command | Description |
|---------|---------|-------------|
| **🎮 Full Menu** | `./scripts/setup.sh` | Complete interactive management |
| **🚀 Quick Launch** | `./setup.sh` | Wrapper script (calls scripts/setup.sh) |
| **🎮 Full Menu** | `./scripts/setup.sh` | Complete interactive management |
| **🚀 Quick Launch** | `./setup.sh` | Wrapper script (calls scripts/setup.sh) |
| **🔄 Cluster Manager** | `./scripts/cluster-manager.sh` | **NEW: Complete cluster lifecycle** |
| **🌐 Portal Access** | `./scripts/access-portal.sh` | Direct portal access |
| **🧹 Cleanup** | `./scripts/cleanup.sh` | Resource cleanup |

## 🔧 Prerequisites

### Required Tools
```bash
# Install on macOS
brew install --cask docker
brew install kubectl kind

# Verify installation
docker --version && kubectl version --client && kind version
```

### System Requirements
- **Docker Desktop** (running)
- **8GB+ RAM** (4GB+ available for Docker)
- **10GB+ disk space**
- **macOS 10.15+**, **Linux**, or **Windows with WSL2**

## 🚀 Deployment Workflow

### Option 1: Interactive Menu (Recommended)
```bash
./scripts/setup.sh
# Follow the menu prompts:
# 11) Check prerequisites 
# 1) Create cluster
# 2) Deploy AWX  
# 3) Start access
```

### Option 2: Quick Launch  
```bash
./setup.sh  # Launches the interactive menu
```

### Option 3: Direct Portal Access (if already deployed)
```bash
./scripts/access-portal.sh
```

## 🌐 Access Information

After successful deployment:

| Access Method | URL | Usage |
|---------------|-----|-------|
| **🌐 Network** | `http://awx-192-168-1-243.nip.io:9080` | Host IP access (configured) |
| **🏠 Local** | `http://localhost:9080` | Port-forward access (automatic) |

**Default Credentials:**
- **Username:** `admin`  
- **Password:** Auto-generated (shown in setup output)

## 🎯 Production Features

- **✅ Latest Stable**: AWX v24.6.1 + Operator v2.19.1
- **🔒 Security**: No exposed host ports, secure defaults
- **💾 Persistence**: PostgreSQL data survives restarts
- **🔄 High Availability**: 3 web pods, 4 task pods  
- **📊 Monitoring**: Real-time health checks and status
- **🛠️ Maintenance**: Automated backup and cleanup tools

## 🆘 Troubleshooting

### Quick Diagnostics
```bash
./scripts/setup.sh  # → Option 9 (Troubleshooting)
# OR
kubectl get pods -n awx          # Check pod status
kubectl get svc -n awx           # Check services  
docker ps                        # Check Kind containers
```

### Common Issues
- **Port conflicts**: Use option 9 → Check port status
- **Docker not running**: Start Docker Desktop
- **Cluster not responding**: Use option 10 → Cleanup and recreate
- **AWX pods not ready**: Wait 5-10 minutes for initialization

## 📋 Project Status

**✅ PRODUCTION READY**
- **Repository**: Cleaned to 8 essential files
- **Deployment**: Successfully tested AWX v24.6.1  
- **Network**: Host IP access configured
- **Management**: Full menu-driven system operational

## 📄 License

MIT License - see [docs/LICENSE](docs/LICENSE) for details.

---

**🎮 Ready to get started? Just run `./setup.sh` and follow the interactive guide!**
