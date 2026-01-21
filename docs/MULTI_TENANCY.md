# Multi-Tenancy Guide - UIM IaaS Platform

## Overview

The UIM IaaS Platform now includes comprehensive **multi-tenancy** support, enabling complete isolation of resources between different tenants (organizations/customers). Each tenant has their own isolated view of:

- Virtual machines and containers
- Storage volumes and buckets
- Networks, subnets, and security groups
- Metrics and alerts
- Users and API keys

## Architecture

### Tenant Isolation Model

```
┌─────────────────────────────────────────────────────────┐
│                     API Gateway                          │
│  - Extracts token from request                          │
│  - Verifies with Auth Service                           │
│  - Adds X-Tenant-ID header                              │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│              Backend Services                            │
│  - Read X-Tenant-ID header                              │
│  - Filter all data by tenant ID                         │
│  - Enforce tenant ownership                             │
└─────────────────────────────────────────────────────────┘
```

### How It Works

1. **Authentication**: User logs in and receives a token
2. **Token Contains Tenant**: The token is associated with a tenant ID
3. **API Gateway**: Verifies token and adds `X-Tenant-ID` header
4. **Backend Services**: Filter all operations by tenant ID
5. **Data Isolation**: Users only see their tenant's resources

## Tenant Management

### Create a Tenant

```bash
# Login as admin
TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

# Create new tenant
curl -X POST http://localhost:8080/api/v1/auth/tenants \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Corporation",
    "description": "Main production tenant",
    "metadata": {
      "industry": "technology",
      "size": "enterprise"
    }
  }'
```

Response:
```json
{
  "id": "tenant-uuid-here",
  "name": "Acme Corporation",
  "description": "Main production tenant",
  "active": true,
  "createdAt": 1737468000,
  "updatedAt": 1737468000,
  "metadata": {
    "industry": "technology",
    "size": "enterprise"
  }
}
```

### List All Tenants

```bash
curl http://localhost:8080/api/v1/auth/tenants \
  -H "Authorization: Bearer $TOKEN"
```

### Get Tenant Details

```bash
curl http://localhost:8080/api/v1/auth/tenants/{tenant-id} \
  -H "Authorization: Bearer $TOKEN"
```

### Update Tenant

```bash
curl -X PUT http://localhost:8080/api/v1/auth/tenants/{tenant-id} \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Corp (Updated)",
    "description": "Updated description",
    "active": true
  }'
```

### Delete Tenant

```bash
curl -X DELETE http://localhost:8080/api/v1/auth/tenants/{tenant-id} \
  -H "Authorization: Bearer $TOKEN"
```

**Note**: Cannot delete a tenant with active users.

## User Management (Multi-Tenant)

### Create User for Specific Tenant

```bash
curl -X POST http://localhost:8080/api/v1/auth/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john.doe",
    "email": "john@acme.com",
    "password": "secure123",
    "tenantId": "tenant-uuid-here",
    "role": "user"
  }'
```

### List Users (Tenant-Filtered)

When you list users, you only see users from your tenant:

```bash
curl http://localhost:8080/api/v1/auth/users \
  -H "Authorization: Bearer $TOKEN"
```

## Resource Isolation

### Compute Resources

All compute instances are automatically tagged with tenant ID:

```bash
# Create instance - automatically associated with your tenant
curl -X POST http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-server",
    "type": "vm",
    "flavor": "medium",
    "imageId": "ubuntu-22.04"
  }'

# List instances - only shows your tenant's instances
curl http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $TOKEN"
```

Response includes `tenantId`:
```json
{
  "instances": [
    {
      "id": "instance-uuid",
      "name": "web-server",
      "tenantId": "your-tenant-id",
      "type": "vm",
      "flavor": "medium",
      "status": "running"
    }
  ]
}
```

### Storage Resources

Volumes and buckets are isolated per tenant:

```bash
# Create volume for your tenant
curl -X POST http://localhost:8080/api/v1/storage/volumes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "data-volume",
    "sizeGB": 100
  }'

# Create bucket for your tenant
curl -X POST http://localhost:8080/api/v1/storage/buckets \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-bucket"
  }'
```

### Network Resources

Networks, subnets, and security groups are tenant-isolated:

```bash
# Create network for your tenant
curl -X POST http://localhost:8080/api/v1/network/networks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "prod-network",
    "cidr": "10.0.0.0/16"
  }'

# Create subnet
curl -X POST http://localhost:8080/api/v1/network/subnets \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "prod-subnet",
    "networkId": "network-uuid",
    "cidr": "10.0.1.0/24",
    "gateway": "10.0.1.1"
  }'
```

### Monitoring Resources

Metrics and alerts are tenant-specific:

```bash
# Record metric - automatically tagged with tenant
curl -X POST http://localhost:8080/api/v1/monitoring/metrics \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "cpu.usage",
    "value": 75.5,
    "type": "gauge",
    "labels": {
      "instance": "web-server"
    }
  }'

# Get dashboard - shows only your tenant's metrics
curl http://localhost:8080/api/v1/monitoring/dashboard \
  -H "Authorization: Bearer $TOKEN"
```

## Security & Access Control

### Tenant Ownership Verification

All resource operations verify tenant ownership:

1. **Read Operations**: Filter results to only show tenant's resources
2. **Modify Operations**: Verify resource belongs to tenant before modification
3. **Delete Operations**: Verify resource belongs to tenant before deletion

Example:
```bash
# Try to access another tenant's instance - returns 403 Forbidden
curl http://localhost:8080/api/v1/compute/instances/other-tenant-instance \
  -H "Authorization: Bearer $TOKEN"

# Response:
{
  "error": "Access denied"
}
```

### Cross-Tenant Access Prevention

- Users cannot see resources from other tenants
- Users cannot modify resources from other tenants
- API Gateway enforces tenant context on all requests
- Backend services validate tenant ownership

## Complete Workflow Example

### 1. Setup: Create Tenant & User

```bash
# Admin creates tenant
ADMIN_TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

TENANT_ID=$(curl -X POST http://localhost:8080/api/v1/auth/tenants \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"TechCorp","description":"Technology company"}' \
  | jq -r '.id')

# Create user in new tenant
curl -X POST http://localhost:8080/api/v1/auth/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\":\"techcorp-admin\",
    \"email\":\"admin@techcorp.com\",
    \"password\":\"secure123\",
    \"tenantId\":\"$TENANT_ID\",
    \"role\":\"admin\"
  }"
```

### 2. Tenant User Login

```bash
# Tenant user logs in
USER_TOKEN=$(curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"techcorp-admin","password":"secure123"}' \
  | jq -r '.token')
```

### 3. Create Resources

```bash
# Create network
NETWORK_ID=$(curl -X POST http://localhost:8080/api/v1/network/networks \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"prod-net","cidr":"10.0.0.0/16"}' \
  | jq -r '.id')

# Create volume
VOLUME_ID=$(curl -X POST http://localhost:8080/api/v1/storage/volumes \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"data-vol","sizeGB":100}' \
  | jq -r '.id')

# Create instance
INSTANCE_ID=$(curl -X POST http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\":\"app-server\",
    \"type\":\"vm\",
    \"flavor\":\"medium\",
    \"imageId\":\"ubuntu-22.04\",
    \"networkIds\":[\"$NETWORK_ID\"],
    \"volumeIds\":[\"$VOLUME_ID\"]
  }" | jq -r '.id')
```

### 4. View Tenant Resources

```bash
# List all instances (tenant-filtered)
curl http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $USER_TOKEN" | jq

# List all volumes (tenant-filtered)
curl http://localhost:8080/api/v1/storage/volumes \
  -H "Authorization: Bearer $USER_TOKEN" | jq

# List all networks (tenant-filtered)
curl http://localhost:8080/api/v1/network/networks \
  -H "Authorization: Bearer $USER_TOKEN" | jq

# View monitoring dashboard (tenant-filtered)
curl http://localhost:8080/api/v1/monitoring/dashboard \
  -H "Authorization: Bearer $USER_TOKEN" | jq
```

## Best Practices

### 1. Tenant Naming

- Use clear, descriptive names
- Include organization/department info
- Consider naming conventions: `{org}-{env}` (e.g., `acme-production`)

### 2. User Management

- Create admin user for each tenant
- Use role-based access control
- Regularly audit user access

### 3. Resource Organization

- Use metadata tags for additional organization
- Implement naming conventions within tenants
- Use separate networks per environment

### 4. Monitoring

- Set up tenant-specific alerts
- Monitor resource usage per tenant
- Track costs per tenant (future feature)

### 5. Security

- Rotate API keys regularly
- Use strong passwords
- Enable HTTPS in production
- Implement rate limiting per tenant

## API Endpoints Summary

### Tenant Management
- `GET /api/v1/auth/tenants` - List all tenants
- `GET /api/v1/auth/tenants/:id` - Get tenant details
- `POST /api/v1/auth/tenants` - Create tenant
- `PUT /api/v1/auth/tenants/:id` - Update tenant
- `DELETE /api/v1/auth/tenants/:id` - Delete tenant

### User Management (Multi-Tenant)
- `GET /api/v1/auth/users` - List users (tenant-filtered)
- `POST /api/v1/auth/users` - Create user (with tenantId)
- All user operations respect tenant isolation

### All Resource Endpoints (Tenant-Isolated)
- Compute: All instance operations
- Storage: All volume and bucket operations
- Network: All network, subnet, and security group operations
- Monitoring: All metrics and alerts operations

## Technical Details

### Headers

**Request Headers:**
- `Authorization: Bearer {token}` - Authentication token

**Internal Headers (API Gateway → Services):**
- `X-Tenant-ID: {tenant-id}` - Tenant context (added by API Gateway)

### Database Schema Changes

All resources now include:
```d
struct Resource {
    string id;
    string tenantId;  // <-- New field
    // ... other fields
}
```

### Verification Flow

```
1. User Request → API Gateway
2. API Gateway calls Auth Service to verify token
3. Auth Service returns user info + tenantId
4. API Gateway adds X-Tenant-ID header
5. Backend Service reads X-Tenant-ID header
6. Backend Service filters by tenantId
7. Response only includes tenant's resources
```

## Troubleshooting

### Issue: Cannot see resources

**Solution**: Verify you're logged in as the correct tenant user:
```bash
# Verify token
curl http://localhost:8080/api/v1/auth/verify \
  -H "Authorization: Bearer $TOKEN"
```

### Issue: Access denied error

**Cause**: Trying to access resource from another tenant

**Solution**: Ensure the resource ID belongs to your tenant

### Issue: Empty resource lists

**Cause**: No resources created for your tenant yet

**Solution**: Create resources - they'll automatically be associated with your tenant

## Migration from Single-Tenant

If you have existing data:

1. All existing resources are assigned to "default" tenant
2. Admin user is in "default" tenant
3. Create new tenants for organizations
4. Create users in new tenants
5. Optionally migrate resources (future feature)

## Future Enhancements

- [ ] Resource quotas per tenant
- [ ] Billing and metering per tenant
- [ ] Tenant-specific rate limiting
- [ ] Resource migration between tenants
- [ ] Hierarchical tenants (sub-tenants)
- [ ] Tenant suspension/reactivation
- [ ] Cross-tenant resource sharing
- [ ] Tenant usage analytics

## Summary

Multi-tenancy in UIM IaaS Platform provides:

✅ **Complete Isolation**: Each tenant has isolated resources
✅ **Automatic Enforcement**: API Gateway and services handle isolation
✅ **Secure**: Cross-tenant access is prevented
✅ **Simple API**: Works transparently with existing endpoints
✅ **Scalable**: Support unlimited tenants
✅ **Auditable**: All resources tracked by tenant

For more information, see:
- [API Examples](API_EXAMPLES.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Quick Start Guide](QUICKSTART.md)
