# 🚀 AWX Quick Start & Management Reference

> **Essential commands for your production-ready AWX on Kind deployment**

## 🎯 **Instant Access**

**🌐 Portal URL:** http://awx-192-168-1-243.nip.io:9080  
**🔐 Login:** `admin` / `kzUfY19ptzjlURRkEFYtnZiLxDzLd1iE`

```bash
# Open portal instantly
open http://awx-192-168-1-243.nip.io:9080
```

---

## 🎮 **Management Scripts**

### **🔄 Complete Cluster Manager (NEW!)**
```bash
# Interactive menu with 9 options
./scripts/cluster-manager.sh

# Direct commands  
./scripts/cluster-manager.sh health     # System diagnostics
./scripts/cluster-manager.sh restart    # Restart cluster
./scripts/cluster-manager.sh create     # Fresh deployment
./scripts/cluster-manager.sh access     # Smart portal access
./scripts/cluster-manager.sh destroy    # Nuclear option ⚠️
```

### **🎮 Original Setup Menu**
```bash
# 13-option comprehensive menu
./scripts/setup.sh

# Quick launcher
./setup.sh
```

### **🌐 Portal Access**
```bash
# Simple portal access + browser
./scripts/access-portal.sh
```

---

## ⚡ **Emergency Procedures**

### **🚨 Portal Not Working?**
```bash
# 1. Quick health check
./scripts/cluster-manager.sh health

# 2. If health fails, restart  
./scripts/cluster-manager.sh restart

# 3. Nuclear option (rebuilds everything)
./scripts/cluster-manager.sh destroy
./scripts/cluster-manager.sh create
```

### **🔄 Common Issues & Fixes**

| Problem | Solution |
|---------|----------|
| **Portal not accessible** | `./scripts/cluster-manager.sh access` |
| **Cluster not responding** | `./scripts/cluster-manager.sh restart` |
| **Pods stuck/failing** | `./scripts/cluster-manager.sh create` |
| **After Mac restart** | `./scripts/cluster-manager.sh health` then `restart` |
| **Complete reset needed** | `./scripts/cluster-manager.sh destroy` then `create` |

---

## 📋 **System Status Commands**

```bash
# Quick status check
kubectl get pods -n awx
curl -I http://awx-192-168-1-243.nip.io:9080

# Get admin password  
kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' | base64 -d

# Check cluster info
kind get clusters
docker ps | grep awx-cluster

# Resource usage
kubectl top pods -n awx 2>/dev/null
```

---

## 🔧 **Manual Operations**

### **Start/Stop Cluster**
```bash
# Stop (preserve data)
./scripts/cluster-manager.sh stop

# Start (resume)  
./scripts/cluster-manager.sh start

# Restart (keep data)
./scripts/cluster-manager.sh restart
```

### **Portal Access Methods**
```bash
# Method 1: Host IP (Best - persistent)
open http://awx-192-168-1-243.nip.io:9080

# Method 2: Port-forward (fallback)
kubectl port-forward -n awx svc/awx-service 9080:80 &
open http://localhost:9080

# Stop port-forward
pkill -f "kubectl.*port-forward.*9080"
```

---

## 📚 **Documentation Quick Access**

| Document | Purpose | Command |
|----------|---------|---------|
| **README.md** | Project overview | `less README.md` |
| **ARCHITECTURE.md** | Technical architecture | `less ARCHITECTURE.md` |
| **CLUSTER-MANAGEMENT.md** | Complete technical guide | `less CLUSTER-MANAGEMENT.md` |
| **PRODUCTION-READY.md** | Deployment status | `less PRODUCTION-READY.md` |

---

## 🎯 **Project Structure**

```
awx-on-kind-k8s-cluster/
├── 📄 setup.sh                       # Quick launcher  
├── 📚 README.md                      # Project guide
├── 🏗️ ARCHITECTURE.md               # Technical architecture
├── 🔄 CLUSTER-MANAGEMENT.md          # Complete lifecycle guide  
├── 🎉 PRODUCTION-READY.md            # Deployment validation
├── 🚀 QUICK-REFERENCE.md             # This file!
├── 🔧 resources/                     # K8s configurations
└── 🎯 scripts/
    ├── setup.sh                    # 13-option main menu
    ├── cluster-manager.sh          # 🔄 Complete lifecycle manager
    ├── access-portal.sh            # Simple portal access
    └── cleanup.sh                  # Resource cleanup
```

---

## 💡 **Pro Tips**

1. **✅ Always use host IP access** - persistent, no port-forwards needed
2. **✅ Run health check first** when troubleshooting  
3. **✅ Use cluster-manager.sh** for lifecycle operations
4. **✅ Keep this reference handy** for quick commands
5. **✅ Data persists** through restarts but not destroy operations

---

## 🎊 **Production Features**

- ✅ **AWX v24.6.1** with Operator v2.19.1  
- ✅ **Host IP access** via nip.io domain
- ✅ **Interactive management** with comprehensive menus
- ✅ **Self-healing** cluster with automatic recovery
- ✅ **Persistent data** survives restarts
- ✅ **Complete documentation** for all skill levels

**🌐 Start using AWX now:** http://awx-192-168-1-243.nip.io:9080

---

**📝 Generated:** November 23, 2025 | **🔗 Project:** AWX on Kind v24.6.1
