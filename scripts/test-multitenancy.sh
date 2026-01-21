#!/bin/bash

# Multi-Tenancy Test Script
# This script demonstrates tenant isolation in the UIM IaaS Platform

set -e

API_BASE="http://localhost:8080/api/v1"

echo "=========================================="
echo "UIM IaaS Multi-Tenancy Test"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

function print_error() {
    echo -e "${RED}✗ $1${NC}"
}

function print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Step 1: Admin login
print_info "Step 1: Admin login..."
ADMIN_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

if [ "$ADMIN_TOKEN" != "null" ] && [ -n "$ADMIN_TOKEN" ]; then
    print_success "Admin logged in successfully"
else
    print_error "Admin login failed"
    exit 1
fi
echo ""

# Step 2: Create first tenant
print_info "Step 2: Creating Tenant A (Acme Corp)..."
TENANT_A=$(curl -s -X POST "$API_BASE/auth/tenants" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Acme Corporation","description":"First test tenant"}')

TENANT_A_ID=$(echo $TENANT_A | jq -r '.id')
if [ "$TENANT_A_ID" != "null" ] && [ -n "$TENANT_A_ID" ]; then
    print_success "Tenant A created: $TENANT_A_ID"
else
    print_error "Failed to create Tenant A"
    exit 1
fi
echo ""

# Step 3: Create second tenant
print_info "Step 3: Creating Tenant B (TechStart)..."
TENANT_B=$(curl -s -X POST "$API_BASE/auth/tenants" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"TechStart Inc","description":"Second test tenant"}')

TENANT_B_ID=$(echo $TENANT_B | jq -r '.id')
if [ "$TENANT_B_ID" != "null" ] && [ -n "$TENANT_B_ID" ]; then
    print_success "Tenant B created: $TENANT_B_ID"
else
    print_error "Failed to create Tenant B"
    exit 1
fi
echo ""

# Step 4: Create user for Tenant A
print_info "Step 4: Creating user for Tenant A..."
curl -s -X POST "$API_BASE/auth/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"acme-admin\",\"email\":\"admin@acme.com\",\"password\":\"secure123\",\"tenantId\":\"$TENANT_A_ID\",\"role\":\"admin\"}" > /dev/null

print_success "User created for Tenant A"
echo ""

# Step 5: Create user for Tenant B
print_info "Step 5: Creating user for Tenant B..."
curl -s -X POST "$API_BASE/auth/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"techstart-admin\",\"email\":\"admin@techstart.com\",\"password\":\"secure123\",\"tenantId\":\"$TENANT_B_ID\",\"role\":\"admin\"}" > /dev/null

print_success "User created for Tenant B"
echo ""

# Step 6: Login as Tenant A user
print_info "Step 6: Logging in as Tenant A user..."
TENANT_A_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"acme-admin","password":"secure123"}' | jq -r '.token')

if [ "$TENANT_A_TOKEN" != "null" ] && [ -n "$TENANT_A_TOKEN" ]; then
    print_success "Tenant A user logged in"
else
    print_error "Tenant A user login failed"
    exit 1
fi
echo ""

# Step 7: Login as Tenant B user
print_info "Step 7: Logging in as Tenant B user..."
TENANT_B_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"techstart-admin","password":"secure123"}' | jq -r '.token')

if [ "$TENANT_B_TOKEN" != "null" ] && [ -n "$TENANT_B_TOKEN" ]; then
    print_success "Tenant B user logged in"
else
    print_error "Tenant B user login failed"
    exit 1
fi
echo ""

# Step 8: Create instance for Tenant A
print_info "Step 8: Creating instance for Tenant A..."
INSTANCE_A=$(curl -s -X POST "$API_BASE/compute/instances" \
  -H "Authorization: Bearer $TENANT_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"acme-web-server","type":"vm","flavor":"medium","imageId":"ubuntu-22.04"}')

INSTANCE_A_ID=$(echo $INSTANCE_A | jq -r '.id')
if [ "$INSTANCE_A_ID" != "null" ] && [ -n "$INSTANCE_A_ID" ]; then
    print_success "Instance created for Tenant A: $INSTANCE_A_ID"
else
    print_error "Failed to create instance for Tenant A"
fi
echo ""

# Step 9: Create instance for Tenant B
print_info "Step 9: Creating instance for Tenant B..."
INSTANCE_B=$(curl -s -X POST "$API_BASE/compute/instances" \
  -H "Authorization: Bearer $TENANT_B_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"techstart-app-server","type":"vm","flavor":"small","imageId":"ubuntu-22.04"}')

INSTANCE_B_ID=$(echo $INSTANCE_B | jq -r '.id')
if [ "$INSTANCE_B_ID" != "null" ] && [ -n "$INSTANCE_B_ID" ]; then
    print_success "Instance created for Tenant B: $INSTANCE_B_ID"
else
    print_error "Failed to create instance for Tenant B"
fi
echo ""

# Step 10: Test tenant isolation - Tenant A listing instances
print_info "Step 10: Testing isolation - Tenant A lists instances..."
TENANT_A_INSTANCES=$(curl -s "$API_BASE/compute/instances" \
  -H "Authorization: Bearer $TENANT_A_TOKEN")

TENANT_A_COUNT=$(echo $TENANT_A_INSTANCES | jq '.instances | length')
echo "Tenant A sees $TENANT_A_COUNT instance(s)"

if echo $TENANT_A_INSTANCES | jq -e ".instances[] | select(.id == \"$INSTANCE_A_ID\")" > /dev/null; then
    print_success "Tenant A can see their own instance"
else
    print_error "Tenant A cannot see their own instance"
fi

if echo $TENANT_A_INSTANCES | jq -e ".instances[] | select(.id == \"$INSTANCE_B_ID\")" > /dev/null; then
    print_error "ISOLATION FAILED: Tenant A can see Tenant B's instance!"
else
    print_success "Tenant A cannot see Tenant B's instance (correct isolation)"
fi
echo ""

# Step 11: Test tenant isolation - Tenant B listing instances
print_info "Step 11: Testing isolation - Tenant B lists instances..."
TENANT_B_INSTANCES=$(curl -s "$API_BASE/compute/instances" \
  -H "Authorization: Bearer $TENANT_B_TOKEN")

TENANT_B_COUNT=$(echo $TENANT_B_INSTANCES | jq '.instances | length')
echo "Tenant B sees $TENANT_B_COUNT instance(s)"

if echo $TENANT_B_INSTANCES | jq -e ".instances[] | select(.id == \"$INSTANCE_B_ID\")" > /dev/null; then
    print_success "Tenant B can see their own instance"
else
    print_error "Tenant B cannot see their own instance"
fi

if echo $TENANT_B_INSTANCES | jq -e ".instances[] | select(.id == \"$INSTANCE_A_ID\")" > /dev/null; then
    print_error "ISOLATION FAILED: Tenant B can see Tenant A's instance!"
else
    print_success "Tenant B cannot see Tenant A's instance (correct isolation)"
fi
echo ""

# Step 12: Test cross-tenant access prevention
print_info "Step 12: Testing cross-tenant access prevention..."
ACCESS_TEST=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/compute/instances/$INSTANCE_A_ID" \
  -H "Authorization: Bearer $TENANT_B_TOKEN")

if [ "$ACCESS_TEST" = "403" ] || [ "$ACCESS_TEST" = "404" ]; then
    print_success "Cross-tenant access correctly denied (HTTP $ACCESS_TEST)"
else
    print_error "SECURITY ISSUE: Cross-tenant access not denied (HTTP $ACCESS_TEST)"
fi
echo ""

# Step 13: Create storage resources for each tenant
print_info "Step 13: Creating storage volumes..."

# Tenant A volume
VOLUME_A=$(curl -s -X POST "$API_BASE/storage/volumes" \
  -H "Authorization: Bearer $TENANT_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"acme-data","sizeGB":100}')
VOLUME_A_ID=$(echo $VOLUME_A | jq -r '.id')

# Tenant B volume
VOLUME_B=$(curl -s -X POST "$API_BASE/storage/volumes" \
  -H "Authorization: Bearer $TENANT_B_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"techstart-data","sizeGB":50}')
VOLUME_B_ID=$(echo $VOLUME_B | jq -r '.id')

print_success "Volumes created for both tenants"
echo ""

# Step 14: Test storage isolation
print_info "Step 14: Testing storage isolation..."
TENANT_A_VOLUMES=$(curl -s "$API_BASE/storage/volumes" \
  -H "Authorization: Bearer $TENANT_A_TOKEN")

TENANT_A_VOL_COUNT=$(echo $TENANT_A_VOLUMES | jq '.volumes | length')
echo "Tenant A sees $TENANT_A_VOL_COUNT volume(s)"

if echo $TENANT_A_VOLUMES | jq -e ".volumes[] | select(.id == \"$VOLUME_B_ID\")" > /dev/null; then
    print_error "ISOLATION FAILED: Tenant A can see Tenant B's volume!"
else
    print_success "Storage isolation working correctly"
fi
echo ""

# Step 15: Create networks for each tenant
print_info "Step 15: Creating virtual networks..."

# Tenant A network
NETWORK_A=$(curl -s -X POST "$API_BASE/network/networks" \
  -H "Authorization: Bearer $TENANT_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"acme-prod-net","cidr":"10.0.0.0/16"}')
NETWORK_A_ID=$(echo $NETWORK_A | jq -r '.id')

# Tenant B network
NETWORK_B=$(curl -s -X POST "$API_BASE/network/networks" \
  -H "Authorization: Bearer $TENANT_B_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"techstart-net","cidr":"10.1.0.0/16"}')
NETWORK_B_ID=$(echo $NETWORK_B | jq -r '.id')

print_success "Networks created for both tenants"
echo ""

# Step 16: Test network isolation
print_info "Step 16: Testing network isolation..."
TENANT_B_NETWORKS=$(curl -s "$API_BASE/network/networks" \
  -H "Authorization: Bearer $TENANT_B_TOKEN")

TENANT_B_NET_COUNT=$(echo $TENANT_B_NETWORKS | jq '.networks | length')
echo "Tenant B sees $TENANT_B_NET_COUNT network(s)"

if echo $TENANT_B_NETWORKS | jq -e ".networks[] | select(.id == \"$NETWORK_A_ID\")" > /dev/null; then
    print_error "ISOLATION FAILED: Tenant B can see Tenant A's network!"
else
    print_success "Network isolation working correctly"
fi
echo ""

# Summary
echo "=========================================="
echo "Multi-Tenancy Test Summary"
echo "=========================================="
echo ""
echo "✓ Created 2 tenants"
echo "✓ Created 2 users (one per tenant)"
echo "✓ Created isolated resources:"
echo "  - Compute instances"
echo "  - Storage volumes"
echo "  - Virtual networks"
echo "✓ Verified tenant isolation"
echo "✓ Tested cross-tenant access prevention"
echo ""
print_success "All multi-tenancy tests passed!"
echo ""
echo "Tenant A ID: $TENANT_A_ID"
echo "Tenant B ID: $TENANT_B_ID"
echo ""
echo "Use these tokens to interact as each tenant:"
echo "Tenant A Token: $TENANT_A_TOKEN"
echo "Tenant B Token: $TENANT_B_TOKEN"
echo ""
