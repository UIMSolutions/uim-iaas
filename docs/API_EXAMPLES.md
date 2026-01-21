# Example API calls for testing the UIM IaaS Platform

# Get platform status (no auth required)
curl http://localhost:8080/api/v1/status

# Login to get authentication token
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Save the token from the response
TOKEN="your-token-here"

# ==== COMPUTE SERVICE ====

# List available flavors
curl http://localhost:8080/api/v1/compute/flavors

# Create a new VM instance
curl -X POST http://localhost:8080/api/v1/compute/instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "web-server-01",
    "type": "vm",
    "flavor": "medium",
    "imageId": "ubuntu-22.04",
    "metadata": {"environment": "production"}
  }'

# List all instances
curl http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $TOKEN"

# Get specific instance
curl http://localhost:8080/api/v1/compute/instances/INSTANCE_ID \
  -H "Authorization: Bearer $TOKEN"

# Stop instance
curl -X POST http://localhost:8080/api/v1/compute/instances/INSTANCE_ID/stop \
  -H "Authorization: Bearer $TOKEN"

# Start instance
curl -X POST http://localhost:8080/api/v1/compute/instances/INSTANCE_ID/start \
  -H "Authorization: Bearer $TOKEN"

# ==== STORAGE SERVICE ====

# Create a block volume
curl -X POST http://localhost:8080/api/v1/storage/volumes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "data-volume-01",
    "sizeGB": 100,
    "type": "block"
  }'

# List all volumes
curl http://localhost:8080/api/v1/storage/volumes \
  -H "Authorization: Bearer $TOKEN"

# Attach volume to instance
curl -X POST http://localhost:8080/api/v1/storage/volumes/VOLUME_ID/attach \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"instanceId": "INSTANCE_ID"}'

# Create object storage bucket
curl -X POST http://localhost:8080/api/v1/storage/buckets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "my-data-bucket",
    "region": "us-east-1"
  }'

# ==== NETWORK SERVICE ====

# Create a virtual network
curl -X POST http://localhost:8080/api/v1/network/networks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "prod-network",
    "cidr": "10.0.0.0/16"
  }'

# Create a subnet
curl -X POST http://localhost:8080/api/v1/network/subnets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
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
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "web-servers-sg",
    "description": "Security group for web servers"
  }'

# Add security rule (allow HTTP)
curl -X POST http://localhost:8080/api/v1/network/security-groups/SG_ID/rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "direction": "ingress",
    "protocol": "tcp",
    "portMin": 80,
    "portMax": 80,
    "cidr": "0.0.0.0/0"
  }'

# ==== MONITORING SERVICE ====

# Get monitoring dashboard
curl http://localhost:8080/api/v1/monitoring/dashboard \
  -H "Authorization: Bearer $TOKEN"

# Record a metric
curl -X POST http://localhost:8080/api/v1/monitoring/metrics \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "cpu.usage",
    "type": "gauge",
    "value": 75.5,
    "labels": {
      "instance": "web-server-01",
      "host": "node-1"
    }
  }'

# Get all metrics
curl http://localhost:8080/api/v1/monitoring/metrics \
  -H "Authorization: Bearer $TOKEN"

# Create alert
curl -X POST http://localhost:8080/api/v1/monitoring/alerts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "High CPU Usage",
    "severity": "warning",
    "message": "CPU usage exceeded 80%",
    "source": "compute-service"
  }'

# List active alerts
curl "http://localhost:8080/api/v1/monitoring/alerts?active=true" \
  -H "Authorization: Bearer $TOKEN"

# ==== AUTH SERVICE ====

# Create new user
curl -X POST http://localhost:8080/api/v1/auth/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "username": "developer",
    "email": "dev@example.com",
    "password": "secure123",
    "role": "user"
  }'

# List all users
curl http://localhost:8080/api/v1/auth/users \
  -H "Authorization: Bearer $TOKEN"

# Create API key
curl -X POST http://localhost:8080/api/v1/auth/api-keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "userId": "USER_ID",
    "name": "CI/CD Pipeline Key",
    "scopes": ["compute:read", "compute:write"]
  }'

# Verify token
curl http://localhost:8080/api/v1/auth/verify \
  -H "Authorization: Bearer $TOKEN"
