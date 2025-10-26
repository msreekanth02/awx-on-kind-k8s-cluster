# AWX on Kind - Project Structure

This document outlines the structure and purpose of each file in the AWX on Kind Kubernetes cluster project.

## 📁 Project Overview

This project provides a complete solution for deploying AWX (Ansible Tower) on a local Kind (Kubernetes in Docker) cluster with interactive management capabilities. It features a comprehensive menu-driven interface for user-friendly cluster management.

## 📂 File Structure

```
awx-on-kind-k8s-cluster/
├── 📄 setup.sh                   # Main setup script (convenience wrapper)
├── 📚 docs/                      # Documentation directory
│   ├── README.md                 # Main installation and usage guide
│   ├── Architecture.md           # Detailed system architecture documentation
│   ├── PROJECT-STRUCTURE.md      # This file - project structure overview
│   ├── GETTING-STARTED.md        # Quick start guide for beginners
│   ├── DEPLOYMENT-SUCCESS.md     # Success story and lessons learned
│   ├── PORT-CHANGES.md          # Documentation of port configuration changes
│   ├── INTERACTIVE-FEATURES.md  # Complete interactive setup guide
│   ├── SETUP-COMPLETE.md        # Project completion summary
│   ├── PROJECT-COMPLETE.md      # Final project overview
│   └── LICENSE                  # Project license (MIT)
│
├── 🔧 resources/                 # Configuration files directory
│   ├── kind-cluster-config.yaml # Kind cluster configuration with port mappings
│   ├── awx-instance.yaml        # AWX instance deployment manifest
│   └── awx-pv.yaml             # Persistent volume configuration for storage
│
└── 🎯 scripts/                   # Scripts directory
    ├── setup.sh                 # ⭐ MAIN INTERACTIVE SCRIPT
    ├── quick-deploy.sh          # Automated one-command deployment
    ├── health-check.sh          # Comprehensive system health verification
    ├── verify-deployment.sh     # Deployment status and validation
    ├── access-awx.sh           # AWX access helper with credentials
    ├── backup-awx.sh           # Data backup and export utility
    ├── cleanup.sh              # Resource cleanup and removal
    └── check-ports.sh          # Port conflict detection and resolution
```

## 🎯 Script Categories and Purpose

### 📱 Interactive Management (RECOMMENDED)

**setup.sh** - The primary script providing a comprehensive menu-driven interface for:
- 🏗️ Cluster Management (create, destroy, start, stop)
- ⚙️ AWX Operations (deploy, access, scale, update)
- 🔧 Maintenance & Tools (backup, cleanup, monitoring)
- 🩺 Monitoring & Diagnostics (health checks, logs, troubleshooting)
- 📚 Documentation & Help (guides, references, tips)

### ⚡ Quick Deployment

**quick-deploy.sh** - Automated deployment for experienced users:
- Single-command deployment from cluster creation to AWX access
- Minimal user interaction required
- Error handling and rollback capabilities

### 🛠️ Specialized Utilities

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `health-check.sh` | Comprehensive system diagnostics | When experiencing issues or for regular monitoring |
| `verify-deployment.sh` | Validate deployment status | After deployment or when troubleshooting |
| `access-awx.sh` | Get AWX access credentials and URL | When you need login information |
| `backup-awx.sh` | Create AWX data backups | Before updates or for data protection |
| `cleanup.sh` | Remove AWX resources | When cleaning up or starting fresh |
| `check-ports.sh` | Detect and resolve port conflicts | Before deployment or when having access issues |

## 🚀 Getting Started Workflow

### For New Users (Interactive Experience)
```bash
# 1. Start with the interactive setup
chmod +x setup.sh
./setup.sh

# 2. Follow the menu system:
#    - Option 1: Create cluster
#    - Option 2: Deploy AWX
#    - Option 3: Start access
#    - Option 5: View status dashboard
```

### For Experienced Users (Quick Deployment)
```bash
# Single command deployment
chmod +x scripts/quick-deploy.sh
scripts/quick-deploy.sh
```

### For Maintenance Tasks
```bash
# Health monitoring
scripts/health-check.sh

# Data backup
scripts/backup-awx.sh

# Complete cleanup
scripts/cleanup.sh
```

## 📊 Configuration Files Details

### kind-cluster-config.yaml
- **Purpose**: Defines the Kind cluster configuration
- **Key Features**:
  - Multi-node setup (1 control plane + 2 workers)
  - Port mappings for AWX access (9080:80, 9443:443)
  - Ingress controller support
  - Storage mount configurations

### awx-instance.yaml
- **Purpose**: AWX deployment specification
- **Key Features**:
  - PostgreSQL database configuration
  - Resource requirements and limits
  - Persistent storage configuration
  - Service account and security settings

### awx-pv.yaml
- **Purpose**: Persistent volume setup for data storage
- **Key Features**:
  - Local storage configuration
  - PostgreSQL data persistence
  - Projects and media storage

## 🔄 Workflow Integration

The scripts are designed to work together in a cohesive workflow:

1. **Preparation**: `check-ports.sh` → `setup.sh` (prerequisites)
2. **Deployment**: `setup.sh` or `quick-deploy.sh`
3. **Verification**: `verify-deployment.sh` → `health-check.sh`
4. **Access**: `access-awx.sh` or `setup.sh` (port forwarding)
5. **Maintenance**: `backup-awx.sh` → `health-check.sh`
6. **Cleanup**: `cleanup.sh` or `setup.sh` (cleanup options)

## 🎨 User Experience Features

### Color-Coded Interface
- 🔴 **Red**: Errors and warnings
- 🟢 **Green**: Success messages and completion
- 🟡 **Yellow**: Warnings and prompts
- 🔵 **Blue**: Information and progress
- 🟣 **Purple**: Working/processing status
- 🟦 **Cyan**: Headers and highlights

### Interactive Elements
- **Status Dashboard**: Real-time cluster and AWX status
- **Menu Navigation**: Intuitive number-based selections
- **Progress Indicators**: Visual feedback for long operations
- **Error Handling**: Graceful failure recovery and user guidance
- **Help Integration**: Built-in documentation and tips

### Smart Features
- **Prerequisites Checking**: Automatic tool availability verification
- **Conflict Detection**: Port and resource conflict identification
- **Health Monitoring**: Comprehensive system health verification
- **Backup Management**: Automated data protection
- **Resource Cleanup**: Safe and thorough cleanup procedures

## 🔐 Security Considerations

- **Credential Management**: Secure handling of admin passwords
- **Network Security**: Localhost-only access by default
- **Storage Security**: Proper file permissions and access controls
- **Container Security**: Minimal required privileges

## 📈 Performance Optimization

- **Resource Allocation**: Configurable CPU and memory limits
- **Storage Optimization**: Efficient persistent volume management
- **Network Optimization**: Optimized port forwarding and ingress
- **Scaling Support**: Horizontal pod scaling capabilities

## 🐛 Troubleshooting Resources

Each script includes built-in error handling and diagnostic capabilities:
- Detailed error messages with solution suggestions
- Automatic retry mechanisms for transient failures
- Comprehensive logging for debugging
- Integration with Kubernetes native troubleshooting tools

## 📚 Documentation Hierarchy

1. **README.md**: Primary installation guide and overview
2. **GETTING-STARTED.md**: Beginner-friendly quick start
3. **Architecture.md**: Technical deep-dive and system design
4. **PROJECT-STRUCTURE.md**: This file - project organization
5. **Script comments**: Inline documentation within each script

This structure ensures users can find information at the appropriate level of detail for their needs and experience level.

### Interactive Management
- **setup.sh**: 🌟 **Main script** - Interactive menu system for all operations

### Deployment Scripts
- **quick-deploy.sh**: Fully automated deployment for experienced users
- **access-awx.sh**: Starts port-forwarding and displays credentials

### Monitoring & Verification
- **health-check.sh**: Comprehensive health monitoring with status checks
- **verify-deployment.sh**: Complete deployment verification with colored output
- **check-ports.sh**: Checks for port conflicts before deployment

### Backup & Maintenance
- **backup-awx.sh**: Creates timestamped backups of AWX configuration and data
- **cleanup.sh**: Provides multiple cleanup options (selective or complete)

## 🎨 Script Features

### User Experience
- **Color-coded output** for easy reading
- **Progress indicators** for long-running operations
- **Error handling** with helpful suggestions
- **Interactive prompts** for user choices
- **Status dashboards** with real-time information

### Functionality
- **Prerequisites checking** before operations
- **Automatic error recovery** where possible
- **Multiple deployment methods** (interactive, automated, manual)
- **Comprehensive monitoring** and troubleshooting
- **Flexible cleanup options**

## 🚀 Usage Recommendations

### For New Users
1. Start with `./setup.sh` (interactive menu)
2. Follow the guided workflow
3. Use built-in troubleshooting tools

### For Experienced Users
1. Use `./quick-deploy.sh` for automation
2. Use individual scripts for specific tasks
3. Customize configuration files as needed

### For Troubleshooting
1. Run `./health-check.sh` for quick status
2. Use `./verify-deployment.sh` for detailed verification
3. Access troubleshooting menu in `./setup.sh`

## 🔄 Typical Workflow

```bash
# 1. Initial setup
./setup.sh

# 2. Daily operations
./setup.sh                  # Interactive management
./health-check.sh           # Quick health check
./backup-awx.sh            # Create backup

# 3. Troubleshooting
./verify-deployment.sh      # Full verification
./setup.sh                 # Use troubleshooting menu

# 4. Cleanup
./setup.sh                 # Use cleanup menu
./cleanup.sh               # Manual cleanup options
```

## 📊 File Interdependencies

```
setup.sh (main)
├── Uses: all other scripts
├── Calls: health-check.sh, verify-deployment.sh, check-ports.sh
├── Manages: quick-deploy.sh workflow
└── References: all configuration files

Configuration Files
├── kind-cluster-config.yaml → setup.sh, quick-deploy.sh
├── awx-instance.yaml → setup.sh, quick-deploy.sh
└── awx-pv.yaml → setup.sh, quick-deploy.sh

Monitoring Scripts
├── health-check.sh → Independent, called by setup.sh
├── verify-deployment.sh → Independent, called by setup.sh
└── check-ports.sh → Independent, called by setup.sh, quick-deploy.sh
```

This structure provides maximum flexibility while maintaining ease of use for both beginners and advanced users.
