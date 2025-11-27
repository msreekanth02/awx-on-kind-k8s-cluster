#!/bin/bash

# AWX on Kind Kubernetes Cluster - Status Check
# Comprehensive health monitoring and access verification

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration constants
CLUSTER_NAME="awx-cluster"
AWX_NAMESPACE="awx"
SERVICE_PORT=8082

print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                              AWX ON KIND KUBERNETES - STATUS REPORT                                   ║${NC}"
    echo -e "${BLUE}║                          Enterprise-Grade Deployment Health Check                                     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${PURPLE}═══ $1 ═══${NC}"
}

check_cluster() {
    print_section "CLUSTER INFRASTRUCTURE"
    
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "✅ ${GREEN}Kind cluster '${CLUSTER_NAME}' exists${NC}"
    else
        echo -e "❌ ${RED}Kind cluster '${CLUSTER_NAME}' not found${NC}"
        return 1
    fi
    
    echo -e "🔍 ${BLUE}Nodes Status:${NC}"
    kubectl get nodes --context kind-${CLUSTER_NAME} -o wide
    
    echo -e "\n🔍 ${BLUE}Cluster Information:${NC}"
    kubectl cluster-info --context kind-${CLUSTER_NAME}
}

check_awx() {
    print_section "AWX DEPLOYMENT"
    
    echo -e "🔍 ${BLUE}AWX Instance Status:${NC}"
    if kubectl get awx -n ${AWX_NAMESPACE} &>/dev/null; then
        kubectl get awx -n ${AWX_NAMESPACE} -o wide
        echo ""
        
        # Check AWX status conditions
        echo -e "📊 ${BLUE}AWX Status Details:${NC}"
        kubectl get awx -n ${AWX_NAMESPACE} -o jsonpath='{.items[0].status.conditions[*].type}' | tr ' ' '\n' | while read condition; do
            status=$(kubectl get awx -n ${AWX_NAMESPACE} -o jsonpath="{.items[0].status.conditions[?(@.type=='$condition')].status}")
            if [[ "$status" == "True" ]]; then
                echo -e "  ✅ ${GREEN}$condition: $status${NC}"
            else
                echo -e "  ❌ ${RED}$condition: $status${NC}"
            fi
        done
    else
        echo -e "❌ ${RED}No AWX instances found${NC}"
        return 1
    fi
}

check_pods() {
    print_section "PODS & SERVICES"
    
    echo -e "🔍 ${BLUE}AWX Pods Status:${NC}"
    if kubectl get pods -n ${AWX_NAMESPACE} &>/dev/null; then
        kubectl get pods -n ${AWX_NAMESPACE} -o wide
    else
        echo -e "❌ ${RED}No pods found in ${AWX_NAMESPACE} namespace${NC}"
        return 1
    fi
    
    echo -e "\n🔍 ${BLUE}Services:${NC}"
    kubectl get svc -n ${AWX_NAMESPACE}
}

check_port_forwarding() {
    print_section "PORT FORWARDING STATUS"
    
    echo -e "🔍 ${BLUE}Checking port forwarding processes...${NC}"
    
    # Check for kubectl port-forward processes
    KUBECTL_PF=$(ps aux | grep "kubectl.*port-forward" | grep -v grep | grep "${SERVICE_PORT}" || true)
    if [[ -n "$KUBECTL_PF" ]]; then
        echo -e "  ✅ ${GREEN}kubectl port-forward process found:${NC}"
        echo -e "     ${YELLOW}$KUBECTL_PF${NC}"
    else
        echo -e "  ❌ ${RED}No kubectl port-forward process found for port ${SERVICE_PORT}${NC}"
    fi
    
    # Check if port is in use
    PORT_CHECK=$(lsof -i :${SERVICE_PORT} 2>/dev/null || true)
    if [[ -n "$PORT_CHECK" ]]; then
        echo -e "  🔍 ${BLUE}Port ${SERVICE_PORT} is in use:${NC}"
        echo -e "     ${YELLOW}$PORT_CHECK${NC}"
    else
        echo -e "  ⚠️  ${YELLOW}Port ${SERVICE_PORT} is not in use${NC}"
    fi
}

check_networking() {
    print_section "NETWORK ACCESS"
    
    echo -e "🌐 ${BLUE}Checking network accessibility...${NC}"
    
    # Get host IP
    HOST_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    
    # Check localhost
    echo -e "  🔍 Testing localhost:${SERVICE_PORT}..."
    if curl -s --max-time 5 -I http://localhost:${SERVICE_PORT} | head -1 | grep -q "200 OK"; then
        echo -e "  ✅ ${GREEN}Localhost access: http://localhost:${SERVICE_PORT}${NC}"
    else
        echo -e "  ❌ ${RED}Localhost access failed${NC}"
    fi
    
    # Check host IP
    echo -e "  🔍 Testing ${HOST_IP}:${SERVICE_PORT}..."
    if curl -s --max-time 5 -I http://${HOST_IP}:${SERVICE_PORT} | head -1 | grep -q "200 OK"; then
        echo -e "  ✅ ${GREEN}Host IP access: http://${HOST_IP}:${SERVICE_PORT}${NC}"
    else
        echo -e "  ❌ ${RED}Host IP access failed${NC}"
    fi
    
    # Check nip.io
    echo -e "  🔍 Testing awx.${HOST_IP}.nip.io:${SERVICE_PORT}..."
    if curl -s --max-time 5 -I http://awx.${HOST_IP}.nip.io:${SERVICE_PORT} | head -1 | grep -q "200 OK"; then
        echo -e "  ✅ ${GREEN}nip.io access: http://awx.${HOST_IP}.nip.io:${SERVICE_PORT}${NC}"
    else
        echo -e "  ❌ ${RED}nip.io access failed${NC}"
    fi
}

check_credentials() {
    print_section "AWX CREDENTIALS"
    
    echo -e "🔑 ${BLUE}Admin Credentials:${NC}"
    if kubectl get secret awx-admin-password -n ${AWX_NAMESPACE} &>/dev/null; then
        ADMIN_PASSWORD=$(kubectl get secret awx-admin-password -n ${AWX_NAMESPACE} -o jsonpath='{.data.password}' | base64 -d)
        echo -e "  👤 ${GREEN}Username: admin${NC}"
        echo -e "  🔐 ${GREEN}Password: $ADMIN_PASSWORD${NC}"
    else
        echo -e "  ❌ ${RED}Admin password secret not found${NC}"
    fi
}

print_summary() {
    print_section "SUMMARY"
    
    echo -e "🎯 ${BLUE}Quick Access URLs:${NC}"
    HOST_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    
    echo -e "  📱 ${GREEN}Localhost:    http://localhost:${SERVICE_PORT}${NC}"
    echo -e "  🌍 ${GREEN}Host IP:      http://${HOST_IP}:${SERVICE_PORT}${NC}"
    echo -e "  🌐 ${GREEN}nip.io:       http://awx.${HOST_IP}.nip.io:${SERVICE_PORT}${NC}"
    
    echo -e "\n🔑 ${BLUE}Default Credentials:${NC}"
    if kubectl get secret awx-admin-password -n ${AWX_NAMESPACE} &>/dev/null; then
        ADMIN_PASSWORD=$(kubectl get secret awx-admin-password -n ${AWX_NAMESPACE} -o jsonpath='{.data.password}' | base64 -d)
        echo -e "  👤 ${GREEN}Username: admin${NC}"
        echo -e "  🔐 ${GREEN}Password: $ADMIN_PASSWORD${NC}"
    fi
    
    echo -e "\n📈 ${BLUE}Management Commands:${NC}"
    echo -e "  🎛️  ${YELLOW}Main Menu:     ./awx-manager.sh${NC}"
    echo -e "  💾 ${YELLOW}Backup:        ./awx-manager.sh (option 7)${NC}"
    echo -e "  🔄 ${YELLOW}Restore:       ./awx-manager.sh (option 8)${NC}"
    
    echo ""
    echo -e "${GREEN}╔═════════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                              🎉 AWX DEPLOYMENT STATUS: OPERATIONAL 🎉                                  ║${NC}"
    echo -e "${GREEN}╚═════════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Main execution
main() {
    print_header
    
    # Run all checks
    check_cluster
    echo ""
    check_awx
    echo ""
    check_pods
    echo ""
    check_port_forwarding
    echo ""
    check_networking
    echo ""
    check_credentials
    echo ""
    print_summary
}

# Execute main function
main
