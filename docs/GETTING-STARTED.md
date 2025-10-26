# Getting Started with AWX on Kind

## 🚀 Welcome!

This guide will help you get AWX (Ansible Tower Community Edition) running on your local machine using Kubernetes in Docker (Kind).

## 📋 What You'll Need

- **macOS** (10.15+ recommended)
- **8GB+ RAM** (16GB recommended)
- **20GB+ disk space**
- **Internet connection** (for downloading images)

## ⚡ Quick Start (3 Steps)

### Step 1: Install Prerequisites
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install --cask docker
brew install kubectl kind helm

# Start Docker Desktop
open -a Docker
```

### Step 2: Clone and Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd awx-on-kind-k8s-cluster

# Make scripts executable
chmod +x *.sh

# Run interactive setup
./setup.sh
```

### Step 3: Follow the Menu
The interactive setup will guide you through:
1. ✅ Prerequisites check
2. 🏗️ Create cluster
3. 🎭 Deploy AWX
4. 🌐 Start access
5. 🎉 Access AWX at http://localhost:9080

## 📖 What You'll Get

After successful setup:

- **AWX Web Interface**: Full-featured web UI
- **REST API**: Complete API access
- **Self-Healing**: Automatic recovery from failures
- **Persistent Storage**: Data survives restarts
- **Easy Management**: Interactive scripts for all operations

## 🎯 Next Steps

Once AWX is running, you can:

1. **Login**: Use the admin credentials provided
2. **Create Organization**: Set up your team structure
3. **Add Projects**: Import your Ansible playbooks from Git
4. **Configure Inventories**: Define your infrastructure
5. **Create Job Templates**: Set up automation workflows
6. **Run Jobs**: Execute your automation tasks

## 🆘 Need Help?

- **Interactive Help**: Use `./setup.sh` → Troubleshooting menu
- **Health Check**: Run `./health-check.sh`
- **Verify Setup**: Run `./verify-deployment.sh`
- **Documentation**: Check `README.md` and `Architecture.md`

## 🔧 Common Issues

### Port Conflicts
```bash
./check-ports.sh  # Check for conflicts
./setup.sh        # Use cleanup menu to resolve
```

### Docker Issues
```bash
docker --version  # Verify Docker is installed
docker info       # Check if Docker is running
```

### AWX Not Starting
```bash
./setup.sh        # Use troubleshooting menu
kubectl get pods -n awx  # Check pod status
```

## 🎉 Success Indicators

You'll know everything is working when:
- ✅ All health checks pass
- ✅ AWX web interface loads at http://localhost:9080
- ✅ You can login with admin credentials
- ✅ The setup script shows all green status indicators

---

**Estimated Time**: 10-15 minutes for first-time setup  
**Difficulty**: Beginner-friendly with interactive guidance  
**Support**: Built-in troubleshooting and help system
