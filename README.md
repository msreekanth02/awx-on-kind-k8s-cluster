# AWX on Kind Kubernetes Cluster

> 🎮 **Interactive Management Console** for deploying AWX on local Kind clusters

A comprehensive, user-friendly solution to deploy AWX (Ansible Tower Community Edition) using the AWX Operator on a local Kind Kubernetes cluster. Features an **interactive menu system** for effortless management, self-healing capabilities, and automated troubleshooting.

## 🚀 Quick Start

```bash
# 1. Clone and navigate to the project
git clone <your-repo-url>
cd awx-on-kind-k8s-cluster

# 2. Launch the interactive setup
./setup.sh

# 3. Follow the guided workflow and enjoy AWX at http://localhost:9080!
```

## 📁 Project Structure

```
awx-on-kind-k8s-cluster/
├── 📄 setup.sh                   # Main interactive setup (START HERE!)
├── 📚 docs/                      # Complete documentation
│   ├── README.md                 # Detailed installation guide
│   ├── INTERACTIVE-FEATURES.md   # Interactive setup features
│   ├── Architecture.md           # System architecture
│   └── ...                      # Additional guides
├── 🔧 resources/                 # Kubernetes configurations
│   ├── kind-cluster-config.yaml  # Kind cluster setup
│   ├── awx-instance.yaml        # AWX deployment config
│   └── awx-pv.yaml              # Storage configuration
└── 🎯 scripts/                   # Utility scripts
    ├── setup.sh                 # Main interactive script
    ├── quick-deploy.sh          # Automated deployment
    ├── health-check.sh          # System health checks
    └── ...                      # Additional utilities
```

## 🌟 Key Features

- **🎮 Interactive Management Console**: Color-coded, menu-driven interface
- **🧠 Smart Automation**: Conflict detection, auto-recovery, guided workflows
- **🔄 Self-Healing Infrastructure**: Automatic recovery with multiple replicas
- **🌐 User-Friendly Access**: Web UI accessible via localhost (no port conflicts)
- **💾 Persistent Data Storage**: Data survives restarts and reboots
- **🛡️ Secure by Default**: Port-forwarding without exposing host ports
- **🔧 Built-in Diagnostics**: 21-point health checks with troubleshooting
- **📊 Real-time Monitoring**: Live dashboards and resource monitoring

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **[docs/README.md](docs/README.md)** | Complete installation and usage guide |
| **[docs/INTERACTIVE-FEATURES.md](docs/INTERACTIVE-FEATURES.md)** | Interactive setup features guide |
| **[docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)** | Beginner-friendly quick start |
| **[docs/Architecture.md](docs/Architecture.md)** | Technical architecture details |

## ⚡ Quick Commands

| Action | Command |
|--------|---------|
| **Interactive Setup** | `./setup.sh` |
| **Automated Deploy** | `scripts/quick-deploy.sh` |
| **Health Check** | `scripts/health-check.sh` |
| **Verify Deployment** | `scripts/verify-deployment.sh` |
| **Get Access Info** | `scripts/access-awx.sh` |
| **Backup Data** | `scripts/backup-awx.sh` |
| **Cleanup** | `scripts/cleanup.sh` |

## 🎯 Use Cases

- **Development**: Local AWX testing and development
- **Learning**: Hands-on experience with AWX and Kubernetes
- **Prototyping**: Quick automation workflow prototyping
- **Training**: Educational environments and workshops
- **CI/CD**: Local automation testing in pipelines

## 🔧 Prerequisites

- **Docker Desktop** (running)
- **kubectl** (Kubernetes CLI)
- **kind** (Kubernetes in Docker)
- **Helm** (optional but recommended)

Install on macOS:
```bash
brew install --cask docker kubectl kind helm
```

## 🎉 Result

After running the interactive setup, you'll have:

- ✅ **AWX Web Interface**: http://localhost:9080
- ✅ **Admin Access**: Username `admin` with auto-generated password
- ✅ **Self-Healing Cluster**: Automatic recovery from failures
- ✅ **Persistent Storage**: Data survives restarts
- ✅ **Production-Ready**: Fully configured AWX deployment

## 🆘 Support

- **Issues**: Check [docs/README.md](docs/README.md) troubleshooting section
- **Interactive Help**: Run `./setup.sh` → Option 5 (Documentation & Help)
- **Health Check**: Run `scripts/health-check.sh` for diagnostics

## 📄 License

MIT License - see [docs/LICENSE](docs/LICENSE) for details.

---

**🎮 Ready to get started? Just run `./setup.sh` and follow the interactive guide!**
