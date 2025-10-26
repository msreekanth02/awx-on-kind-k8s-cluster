#!/bin/bash

# AWX Deployment Verification Script
# This script performs a complete verification of the AWX deployment

echo "🔍 AWX Deployment Verification"
echo "=================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counter for checks
TOTAL_CHECKS=0
PASSED_CHECKS=0

check() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "[$TOTAL_CHECKS] $description... "
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

echo "🏗️  Infrastructure Checks"
echo "-------------------------"

check "Kind cluster exists" "kind get clusters | grep -q awx-cluster"
check "Kubectl can connect to cluster" "kubectl cluster-info"
check "AWX namespace exists" "kubectl get namespace awx"
check "Required nodes are running" "kubectl get nodes | grep -q Ready"

echo ""
echo "🔧 AWX Operator Checks"
echo "----------------------"

check "AWX Operator is deployed" "kubectl get deployment awx-operator-controller-manager -n awx || kubectl get deployment awx-operator-controller-manager -n awx-operator-system"
check "AWX Operator is ready" "kubectl get pods -n awx | grep awx-operator-controller-manager | grep -q Running"

echo ""
echo "💽 Database Checks"
echo "------------------"

check "PostgreSQL pod is running" "kubectl get pods -n awx | grep awx-postgres | grep -q Running"
check "PostgreSQL service exists" "kubectl get service awx-postgres-15 -n awx"
check "Database is accepting connections" "kubectl exec -n awx awx-postgres-15-0 -- pg_isready"

echo ""
echo "🌐 AWX Application Checks"
echo "-------------------------"

check "AWX instance exists" "kubectl get awx awx -n awx"
check "AWX web pods are running" "kubectl get pods -n awx | grep awx-web | grep -q Running"
check "AWX task pods are running" "kubectl get pods -n awx | grep awx-task | grep -q Running"
check "AWX service exists" "kubectl get service awx-service -n awx"
check "AWX migration completed" "kubectl get jobs -n awx | grep awx-migration | grep -q Complete"

echo ""
echo "🔐 Security & Access Checks"
echo "---------------------------"

check "Admin password secret exists" "kubectl get secret awx-admin-password -n awx"
check "Admin password is readable" "kubectl get secret awx-admin-password -o jsonpath='{.data.password}' -n awx | base64 --decode | grep -q ."

echo ""
echo "🌍 Network & Connectivity Checks"
echo "--------------------------------"

# Check if port-forward is running
if pgrep -f "kubectl port-forward.*awx-service" > /dev/null; then
    echo -e "[$((TOTAL_CHECKS + 1))] Port forwarding is active... ${GREEN}✅ PASS${NC}"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    
    # Test API if port-forward is active
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "[$TOTAL_CHECKS] AWX API is responding... "
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9080/api/v2/ping/ | grep -q "200"; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠️  PARTIAL${NC} (API not responding)"
    fi
    
    # Test web interface
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "[$TOTAL_CHECKS] AWX web interface is accessible... "
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9080/ | grep -q "200"; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠️  PARTIAL${NC} (Web interface not responding)"
    fi
else
    echo -e "[$((TOTAL_CHECKS + 1))] Port forwarding is active... ${YELLOW}⚠️  NOT RUNNING${NC}"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo "                                               💡 Run: kubectl port-forward service/awx-service 9080:80 -n awx"
fi

echo ""
echo "💾 Storage Checks"
echo "----------------"

check "Persistent volumes exist" "kubectl get pv | grep -q awx"
check "Storage directories accessible" "docker exec awx-cluster-worker ls -la /data/postgres"

echo ""
echo "📊 Summary"
echo "=========="
echo ""

# Calculate percentage
PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}🎉 ALL CHECKS PASSED! ($PASSED_CHECKS/$TOTAL_CHECKS)${NC}"
    echo -e "${GREEN}✅ AWX is fully operational and ready to use!${NC}"
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "${YELLOW}⚠️  MOSTLY WORKING ($PASSED_CHECKS/$TOTAL_CHECKS - $PERCENTAGE%)${NC}"
    echo -e "${YELLOW}🔧 Minor issues detected, but AWX should be functional${NC}"
else
    echo -e "${RED}❌ ISSUES DETECTED ($PASSED_CHECKS/$TOTAL_CHECKS - $PERCENTAGE%)${NC}"
    echo -e "${RED}🚨 Significant problems found, AWX may not be fully functional${NC}"
fi

echo ""
echo "🔗 Access Information"
echo "===================="

if kubectl get secret awx-admin-password -n awx &>/dev/null; then
    ADMIN_PASSWORD=$(kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode)
    echo -e "${BLUE}🌐 URL:${NC} http://localhost:9080"
    echo -e "${BLUE}👤 Username:${NC} admin"
    echo -e "${BLUE}🔑 Password:${NC} $ADMIN_PASSWORD"
else
    echo -e "${RED}❌ Could not retrieve admin credentials${NC}"
fi

echo ""
echo "🛠️  Useful Commands"
echo "==================="
echo "  Start port-forward:  kubectl port-forward service/awx-service 9080:80 -n awx"
echo "  Health check:        ./health-check.sh"
echo "  View pods:           kubectl get pods -n awx"
echo "  View logs:           kubectl logs -f deployment/awx-web -n awx"
echo "  Backup:              ./backup-awx.sh"
echo "  Cleanup:             ./cleanup.sh"
echo ""

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    exit 0
elif [ $PERCENTAGE -ge 80 ]; then
    exit 1
else
    exit 2
fi
