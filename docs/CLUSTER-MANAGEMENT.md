# 🔄 AWX Cluster Management Guide

> **Complete technical reference for managing your AWX on Kind deployment**

This document provides step-by-step commands for all cluster lifecycle operations including restart, stop/start, access, and recovery scenarios.

---

## 📋 **Quick Reference**

| Operation | Command | Use Case |
|-----------|---------|----------|
| **🎮 Interactive Management** | `./scripts/cluster-manager.sh` | Full menu-driven management |
| **🌐 Access Portal** | `./scripts/access-portal.sh` | Quick portal access |
| **🩺 Health Check** | `./scripts/cluster-manager.sh health` | System diagnostics |
| **🔄 Restart** | `./scripts/cluster-manager.sh restart` | Restart everything |
| **🏗️ Fresh Deploy** | `./scripts/cluster-manager.sh create` | Clean deployment |

---

## 🎯 **Common Scenarios**

### **Scenario 1: "My portal isn't accessible"**
```bash
# Quick fix - run health check first
./scripts/cluster-manager.sh health

# If health check passes, access portal
./scripts/access-portal.sh

# If health check fails, restart cluster
./scripts/cluster-manager.sh restart
```

### **Scenario 2: "I want to restart everything"**
```bash
# Restart cluster (preserves data)
./scripts/cluster-manager.sh restart

# Or use interactive menu
./scripts/cluster-manager.sh
# Choose option 1 (Restart Cluster)
```

### **Scenario 3: "Something is broken, I want fresh start"**
```bash
# Complete rebuild
./scripts/cluster-manager.sh destroy
./scripts/cluster-manager.sh create

# Or interactive
./scripts/cluster-manager.sh
# Choose option 5 (Destroy & Recreate)
```

---

## 🔧 **Manual Command Reference**

### **🔄 1. Restart Cluster (Keep Data)**

**Purpose:** Restart all components while preserving AWX data and configuration

```bash
cd /Users/sreekanthmatturthi/sree/projects/kind-clusters/my-k8s-project/awx-on-kind-k8s-cluster

echo "🔄 Restarting AWX cluster..."

# Stop port-forwards
pkill -f "kubectl.*port-forward" 2>/dev/null || true

# Restart Docker (restarts Kind containers)
osascript -e 'quit app "Docker"'
sleep 5
open -a Docker

# Wait for Docker
until docker info > /dev/null 2>&1; do
    echo "Waiting for Docker..."
    sleep 5
done

# Verify cluster connectivity
kubectl cluster-info --request-timeout=30s

# Wait for AWX pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-web -n awx --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-task -n awx --timeout=300s

echo "✅ Cluster restarted successfully!"
kubectl get pods -n awx
```

### **🛑 2. Stop Cluster (Preserve Data)**

**Purpose:** Stop cluster to save resources, keep all data

```bash
cd /Users/sreekanthmatturthi/sree/projects/kind-clusters/my-k8s-project/awx-on-kind-k8s-cluster

echo "🛑 Stopping AWX cluster..."

# Stop port-forwards
pkill -f "kubectl.*port-forward" 2>/dev/null || true

# Scale down AWX (optional, saves resources)
kubectl scale deployment awx-web --replicas=0 -n awx
kubectl scale deployment awx-task --replicas=0 -n awx

# Stop Docker
osascript -e 'quit app "Docker"'

echo "✅ Cluster stopped. Data preserved."
```

### **🚀 3. Start Cluster (Resume)**

**Purpose:** Start previously stopped cluster

```bash
cd /Users/sreekanthmatturthi/sree/projects/kind-clusters/my-k8s-project/awx-on-kind-k8s-cluster

echo "🚀 Starting AWX cluster..."

# Start Docker
open -a Docker
until docker info > /dev/null 2>&1; do
    echo "Waiting for Docker..."
    sleep 5
done

# Verify cluster exists
if ! kind get clusters | grep -q "awx-cluster"; then
    echo "❌ Cluster not found. Use create command instead."
    exit 1
fi

# Check connectivity
kubectl cluster-info --request-timeout=30s

# Scale AWX back up
kubectl scale deployment awx-web --replicas=1 -n awx
kubectl scale deployment awx-task --replicas=1 -n awx

# Wait for ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-web -n awx --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-task -n awx --timeout=300s

echo "✅ Cluster started successfully!"
kubectl get pods -n awx
```

### **🌐 4. Access Portal (All Methods)**

**Purpose:** Access AWX portal using best available method

```bash
cd /Users/sreekanthmatturthi/sree/projects/kind-clusters/my-k8s-project/awx-on-kind-k8s-cluster

echo "🌐 AWX Portal Access..."

# Method 1: Host IP (Best - No port-forward needed)
if curl -s -I --connect-timeout 5 http://awx-192-168-1-243.nip.io:9080 | grep -q "200 OK"; then
    echo "✅ Host IP access working!"
    echo "🌍 URL: http://awx-192-168-1-243.nip.io:9080"
    open http://awx-192-168-1-243.nip.io:9080
else
    # Method 2: Port-Forward (Fallback)
    echo "🔌 Setting up port-forward..."
    pkill -f "kubectl.*port-forward.*9080" 2>/dev/null || true
    kubectl port-forward -n awx svc/awx-service 9080:80 > /dev/null 2>&1 &
    sleep 3
    echo "✅ Local access ready!"
    echo "🌍 URL: http://localhost:9080"
    open http://localhost:9080
fi

# Display credentials
echo ""
echo "🔐 Login Credentials:"
echo "Username: admin"
echo "Password: $(kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' | base64 -d)"
```

### **💥 5. Destroy Cluster (Complete Removal)**

**Purpose:** Remove everything for fresh start

```bash
cd /Users/sreekanthmatturthi/sree/projects/kind-clusters/my-k8s-project/awx-on-kind-k8s-cluster

echo "💥 Destroying AWX cluster..."
echo "⚠️  This removes ALL data!"

# Stop port-forwards
pkill -f "kubectl.*port-forward" 2>/dev/null || true

# Delete Kind cluster
kind delete cluster --name awx-cluster

# Clean local data
rm -rf /tmp/awx-data 2>/dev/null || true

# Verify cleanup
if kind get clusters | grep -q "awx-cluster"; then
    echo "❌ Manual cleanup needed:"
    echo "docker stop \$(docker ps -q --filter name=awx-cluster)"
    echo "docker rm \$(docker ps -aq --filter name=awx-cluster)"
else
    echo "✅ Cluster destroyed successfully!"
fi
```

### **🏗️ 6. Create Fresh Cluster**

**Purpose:** Create new cluster from scratch

```bash
cd /Users/sreekanthmatturthi/sree/projects/kind-clusters/my-k8s-project/awx-on-kind-k8s-cluster

echo "🏗️ Creating fresh AWX cluster..."

# Ensure Docker is running
if ! docker info > /dev/null 2>&1; then
    open -a Docker
    until docker info > /dev/null 2>&1; do
        echo "Waiting for Docker..."
        sleep 5
    done
fi

# Create Kind cluster
echo "🐳 Creating Kind cluster..."
kind create cluster --config resources/kind-cluster-config.yaml

# Install NGINX Ingress
echo "🌐 Installing NGINX Ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Configure ingress for host access
echo "🔧 Configuring host access..."
kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
  -p '{"spec":{"template":{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}}}'

kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=120s

# Install AWX Operator
echo "🤖 Installing AWX Operator..."
kubectl apply -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1

# Wait for operator
kubectl wait --for=condition=available deployment/awx-operator-controller-manager \
  -n awx-operator-system --timeout=300s

# Create namespace and storage
echo "📂 Setting up AWX namespace..."
kubectl create namespace awx
mkdir -p /tmp/awx-data
kubectl apply -f resources/awx-pv.yaml

# Deploy AWX
echo "🎯 Deploying AWX v24.6.1..."
kubectl apply -f resources/awx-instance.yaml

# Wait for deployment
echo "⏳ Waiting for AWX (5-10 minutes)..."
kubectl wait --for=condition=complete job -l app.kubernetes.io/name=awx-migration -n awx --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-web -n awx --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=awx-task -n awx --timeout=600s

# Verify and show access info
echo "✅ Verifying deployment..."
kubectl get pods -n awx

echo ""
echo "🌐 Testing portal access..."
sleep 10
if curl -s -I --connect-timeout 10 http://awx-192-168-1-243.nip.io:9080 | grep -q "200 OK"; then
    echo "✅ Host IP access working: http://awx-192-168-1-243.nip.io:9080"
else
    echo "🔌 Setting up port-forward: http://localhost:9080"
    kubectl port-forward -n awx svc/awx-service 9080:80 > /dev/null 2>&1 &
fi

echo ""
echo "🔐 Admin Credentials:"
echo "Username: admin"
echo "Password: $(kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo 'Not ready yet, wait 2-3 minutes')"

echo ""
echo "🎉 FRESH AWX CLUSTER CREATED!"
echo "📊 Summary:"
echo "   ✅ AWX version: v24.6.1"
echo "   ✅ Host access: http://awx-192-168-1-243.nip.io:9080"
echo "   ✅ Local access: http://localhost:9080"
```

---

## 🩺 **Health Check & Diagnostics**

### **Quick Health Check**

```bash
cd /Users/sreekanthmatturthi/sree/projects/kind-clusters/my-k8s-project/awx-on-kind-k8s-cluster

echo "🩺 AWX Health Check"
echo "=================="

# 1. Docker
docker info > /dev/null 2>&1 && echo "✅ Docker running" || echo "❌ Docker not running"

# 2. Kind cluster
kind get clusters | grep -q "awx-cluster" && echo "✅ Kind cluster exists" || echo "❌ Kind cluster missing"

# 3. Kubernetes API
kubectl cluster-info --request-timeout=10s > /dev/null 2>&1 && echo "✅ Kubernetes API accessible" || echo "❌ Kubernetes API not accessible"

# 4. AWX namespace
kubectl get namespace awx > /dev/null 2>&1 && echo "✅ AWX namespace exists" || echo "❌ AWX namespace missing"

# 5. AWX pods
echo "📊 Pod Status:"
kubectl get pods -n awx 2>/dev/null || echo "❌ No pods found"

# 6. Portal access
if curl -s -I --connect-timeout 5 http://awx-192-168-1-243.nip.io:9080 | grep -q "200 OK"; then
    echo "✅ Host IP access: http://awx-192-168-1-243.nip.io:9080"
elif curl -s -I --connect-timeout 5 http://localhost:9080 | grep -q "200 OK"; then
    echo "✅ Local access: http://localhost:9080"
else
    echo "❌ No portal access available"
fi
```

---

## 📋 **Quick Reference Commands**

```bash
# Status check
kubectl get pods -n awx && curl -s -I http://awx-192-168-1-243.nip.io:9080 | head -1

# Portal access (host IP)
open http://awx-192-168-1-243.nip.io:9080

# Portal access (port-forward)
pkill -f "kubectl.*port-forward.*9080"; kubectl port-forward -n awx svc/awx-service 9080:80 > /dev/null 2>&1 & sleep 3; open http://localhost:9080

# Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath='{.data.password}' | base64 -d; echo

# Restart AWX pods only
kubectl rollout restart deployment awx-web awx-task -n awx

# Resource usage
kubectl top pods -n awx 2>/dev/null || echo "Metrics not available"
```

---

## 💡 **Best Practices**

1. **✅ Always use Host IP access** (`http://awx-192-168-1-243.nip.io:9080`) - persistent, no port-forwards needed
2. **✅ Run health checks** before troubleshooting
3. **✅ Use restart** for minor issues, **destroy/create** for major problems
4. **✅ Data persists** through restarts but not destroy operations
5. **✅ Keep this document** handy for reference

---

## 🚨 **Emergency Recovery**

If everything breaks and nothing works:

```bash
# Nuclear option - complete rebuild
./scripts/cluster-manager.sh destroy
sleep 10
./scripts/cluster-manager.sh create
```

This will restore your AWX deployment to a known working state in 5-10 minutes.

---

**📝 Last Updated:** November 23, 2025  
**🔗 Related:** README.md, ARCHITECTURE.md, PRODUCTION-READY.md
