# Example API calls for testing the UIM IaaS Platform

## Basic Setup

# Get platform status (no auth required)
curl http://localhost:8080/api/v1/status

# Login to get authentication token
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Save the token from the response
TOKEN="your-token-here"

## Multi-Tenancy Setup

# Create a new tenant (admin only)
curl -X POST http://localhost:8080/api/v1/auth/tenants \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Acme Corporation",
    "description": "Production tenant for Acme Corp",
    "metadata": {"industry": "technology", "size": "enterprise"}
  }'

# Save the tenant ID
TENANT_ID="tenant-uuid-from-response"

# List all tenants
curl http://localhost:8080/api/v1/auth/tenants \
  -H "Authorization: Bearer $TOKEN"

# Create user for specific tenant
curl -X POST http://localhost:8080/api/v1/auth/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"username\": \"acme-admin\",
    \"email\": \"admin@acme.com\",
    \"password\": \"secure123\",
    \"tenantId\": \"$TENANT_ID\",
    \"role\": \"admin\"
  }"

# Login as tenant user
TENANT_TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"acme-admin","password":"secure123"}' | jq -r '.token')

## COMPUTE SERVICE (Tenant-Isolated)

# All operations below are automatically scoped to the user's tenant

# List available flavors
curl http://localhost:8080/api/v1/compute/flavors

# Create a new VM instance (automatically assigned to your tenant)
curl -X POST http://localhost:8080/api/v1/compute/instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "web-server-01",
    "type": "vm",
    "flavor": "medium",
    "imageId": "ubuntu-22.04",
    "metadata": {"environment": "production"}
  }'

# List all instances (filtered to your tenant only)
curl http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $TENANT_TOKEN"

# Get specific instance (must belong to your tenant)
curl http://localhost:8080/api/v1/compute/instances/INSTANCE_ID \
  -H "Authorization: Bearer $TENANT_TOKEN"

# Stop instance
curl -X POST http://localhost:8080/api/v1/compute/instances/INSTANCE_ID/stop \
  -H "Authorization: Bearer $TENANT_TOKEN"

# Start instance
curl -X POST http://localhost:8080/api/v1/compute/instances/INSTANCE_ID/start \
  -H "Authorization: Bearer $TENANT_TOKEN"

## STORAGE SERVICE (Tenant-Isolated)

# All storage resources are automatically scoped to your tenant

# Create a block volume
curl -X POST http://localhost:8080/api/v1/storage/volumes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "data-volume-01",
    "sizeGB": 100,
    "type": "block"
  }'

# List all volumes (tenant-filtered)
curl http://localhost:8080/api/v1/storage/volumes \
  -H "Authorization: Bearer $TENANT_TOKEN"

# Attach volume to instance (both must belong to your tenant)
curl -X POST http://localhost:8080/api/v1/storage/volumes/VOLUME_ID/attach \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{"instanceId": "INSTANCE_ID"}'

# Create object storage bucket
curl -X POST http://localhost:8080/api/v1/storage/buckets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "my-data-bucket",
    "region": "us-east-1"
  }'

## NETWORK SERVICE (Tenant-Isolated)

# All network resources are automatically scoped to your tenant

# Create a virtual network
curl -X POST http://localhost:8080/api/v1/network/networks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "prod-network",
    "cidr": "10.0.0.0/16"
  }'

# Create a subnet
curl -X POST http://localhost:8080/api/v1/network/subnets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "prod-subnet-01",
    "networkId": "NETWORK_ID",
    "cidr": "10.0.1.0/24",
    "gateway": "10.0.1.1",
    "dhcpEnabled": true,
    "dnsServers": ["8.8.8.8", "8.8.4.4"]
  }'

# Create security group
curl -X POST http://localhost:8080/api/v1/network/security-groups \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "web-servers-sg",
    "description": "Security group for web servers"
  }'

# Add security rule (allow HTTP)
curl -X POST http://localhost:8080/api/v1/network/security-groups/SG_ID/rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "direction": "ingress",
    "protocol": "tcp",
    "portMin": 80,
    "portMax": 80,
    "cidr": "0.0.0.0/0"
  }'

## MONITORING SERVICE (Tenant-Isolated)

# All monitoring data is scoped to your tenant

# Get monitoring dashboard (tenant-filtered metrics)
curl http://localhost:8080/api/v1/monitoring/dashboard \
  -H "Authorization: Bearer $TENANT_TOKEN"

# Record a metric (automatically tagged with your tenant)
curl -X POST http://localhost:8080/api/v1/monitoring/metrics \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "cpu.usage",
    "type": "gauge",
    "value": 75.5,
    "labels": {
      "instance": "web-server-01",
      "host": "node-1"
    }
  }'

# Get all metrics (filtered to your tenant)
curl http://localhost:8080/api/v1/monitoring/metrics \
  -H "Authorization: Bearer $TENANT_TOKEN"

# Create alert (tenant-scoped)
curl -X POST http://localhost:8080/api/v1/monitoring/alerts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "High CPU Usage",
    "severity": "warning",
    "message": "CPU usage exceeded 80%",
    "source": "compute-service"
  }'

# List active alerts (tenant-filtered)
curl "http://localhost:8080/api/v1/monitoring/alerts?active=true" \
  -H "Authorization: Bearer $TENANT_TOKEN"

## AUTH SERVICE (Tenant-Aware)

# Create new user in your tenant
curl -X POST http://localhost:8080/api/v1/auth/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d "{
    \"username\": \"developer\",
    \"email\": \"dev@example.com\",
    \"password\": \"secure123\",
    \"tenantId\": \"$TENANT_ID\",
    \"role\": \"user\"
  }"

# List all users (filtered to your tenant)
curl http://localhost:8080/api/v1/auth/users \
  -H "Authorization: Bearer $TENANT_TOKEN"

# Create API key
curl -X POST http://localhost:8080/api/v1/auth/api-keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "userId": "USER_ID",
    "name": "CI/CD Pipeline Key",
    "scopes": ["compute:read", "compute:write"]
  }'

# Verify token
curl http://localhost:8080/api/v1/auth/verify \
  -H "Authorization: Bearer $TENANT_TOKEN"

## Multi-Tenant Isolation Verification

# Try to access another tenant's resource (should fail with 403)
# This demonstrates tenant isolation in action

# As tenant user 1, create a resource
TENANT1_TOKEN="tenant-1-token"
INSTANCE1=$(curl -X POST http://localhost:8080/api/v1/compute/instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT1_TOKEN" \
  -d '{"name":"tenant1-vm","type":"vm","flavor":"small","imageId":"ubuntu-22.04"}' \
  | jq -r '.id')

# As tenant user 2, try to access tenant 1's resource (will fail)
TENANT2_TOKEN="tenant-2-token"
curl http://localhost:8080/api/v1/compute/instances/$INSTANCE1 \
  -H "Authorization: Bearer $TENANT2_TOKEN"
# Response: {"error":"Access denied"} or 404 Not Found

# List resources as tenant 2 (won't see tenant 1's resources)
curl http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $TENANT2_TOKEN"
# Response: Only tenant 2's instances

## Complete Workflow Example

# Step 1: Admin creates tenant
ADMIN_TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

TENANT=$(curl -X POST http://localhost:8080/api/v1/auth/tenants \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"TechStartup","description":"Tech startup tenant"}')

TENANT_ID=$(echo $TENANT | jq -r '.id')

# Step 2: Admin creates user in tenant
curl -X POST http://localhost:8080/api/v1/auth/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"startup-admin\",\"email\":\"admin@startup.com\",\"password\":\"secure123\",\"tenantId\":\"$TENANT_ID\",\"role\":\"admin\"}"

# Step 3: Tenant user logs in
STARTUP_TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"startup-admin","password":"secure123"}' | jq -r '.token')

# Step 4: Tenant user creates infrastructure
# Create network
NET_ID=$(curl -X POST http://localhost:8080/api/v1/network/networks \
  -H "Authorization: Bearer $STARTUP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"app-network","cidr":"10.0.0.0/16"}' | jq -r '.id')

# Create volume
VOL_ID=$(curl -X POST http://localhost:8080/api/v1/storage/volumes \
  -H "Authorization: Bearer $STARTUP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"app-data","sizeGB":100}' | jq -r '.id')

# Create instance
INST_ID=$(curl -X POST http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $STARTUP_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"app-server\",\"type\":\"vm\",\"flavor\":\"medium\",\"imageId\":\"ubuntu-22.04\",\"networkIds\":[\"$NET_ID\"],\"volumeIds\":[\"$VOL_ID\"]}" | jq -r '.id')

# Step 5: View all tenant resources
echo "=== Tenant Infrastructure ==="
curl http://localhost:8080/api/v1/compute/instances -H "Authorization: Bearer $STARTUP_TOKEN" | jq
curl http://localhost:8080/api/v1/storage/volumes -H "Authorization: Bearer $STARTUP_TOKEN" | jq
curl http://localhost:8080/api/v1/network/networks -H "Authorization: Bearer $STARTUP_TOKEN" | jq
curl http://localhost:8080/api/v1/monitoring/dashboard -H "Authorization: Bearer $STARTUP_TOKEN" | jq

## Notes

- All resource operations automatically respect tenant boundaries
- Tokens contain tenant context - no need to manually specify tenant ID in requests
- Cross-tenant access is automatically prevented
- Admin users can manage tenants via `/api/v1/auth/tenants` endpoints
- See [Multi-Tenancy Guide](MULTI_TENANCY.md) for comprehensive documentation
