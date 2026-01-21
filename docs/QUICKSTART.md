# UIM IaaS Platform - Quick Start Guide

## Installation & Setup

### Prerequisites
- D compiler (ldc2): https://dlang.org/download.html
- DUB package manager (included with D)
- Docker: https://docs.docker.com/get-docker/
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl: https://kubernetes.io/docs/tasks/tools/

### Option 1: Local Development (Fastest)

```bash
# Clone or navigate to the project
cd /path/to/uim-iaas

# Run all services locally
make run

# Or manually
./scripts/dev-run.sh
```

Access services at:
- API Gateway: http://localhost:8080
- Auth: http://localhost:8084
- Compute: http://localhost:8081
- Storage: http://localhost:8082
- Network: http://localhost:8083
- Monitoring: http://localhost:8085

### Option 2: Docker Compose

```bash
# Build and run all services
docker-compose up --build

# Or with make
make docker-run

# Stop services
docker-compose down
```

### Option 3: Kubernetes (Production)

```bash
# Build Docker images
make docker-build

# Deploy to Kubernetes
make k8s-deploy

# Check status
make k8s-status

# Port forward to access locally
kubectl port-forward -n uim-iaas svc/api-gateway 8080:80

# View logs
make logs SERVICE=api-gateway

# Undeploy
make k8s-undeploy
```

## Quick Test

### 1. Check Platform Status
```bash
curl http://localhost:8080/api/v1/status
```

### 2. Login (Get Token)
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

Save the token from response:
```bash
export TOKEN="your-token-here"
```

### 3. Create a VM Instance
```bash
curl -X POST http://localhost:8080/api/v1/compute/instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "test-vm",
    "type": "vm",
    "flavor": "small",
    "imageId": "ubuntu-22.04"
  }'
```

### 4. List Instances
```bash
curl http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Create a Volume
```bash
curl -X POST http://localhost:8080/api/v1/storage/volumes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "data-vol",
    "sizeGB": 50
  }'
```

### 6. Create a Network
```bash
curl -X POST http://localhost:8080/api/v1/network/networks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "test-net",
    "cidr": "192.168.0.0/24"
  }'
```

### 7. View Monitoring Dashboard
```bash
curl http://localhost:8080/api/v1/monitoring/dashboard \
  -H "Authorization: Bearer $TOKEN"
```

## Common Commands

### Building
```bash
make build          # Build all services
make clean          # Clean build artifacts
```

### Running
```bash
make run            # Run locally
make docker-run     # Run with Docker Compose
make docker-stop    # Stop Docker Compose
```

### Kubernetes
```bash
make k8s-deploy     # Deploy to K8s
make k8s-undeploy   # Remove from K8s
make k8s-status     # Check status
make logs SERVICE=name  # View logs
```

### Individual Service
```bash
cd services/compute-service
dub build           # Build
dub run             # Run
dub test            # Test
```

## Service Ports

| Service    | Port |
|------------|------|
| Gateway    | 8080 |
| Compute    | 8081 |
| Storage    | 8082 |
| Network    | 8083 |
| Auth       | 8084 |
| Monitoring | 8085 |

## Default Credentials

- Username: `admin`
- Password: `admin123`

**Change these in production!**

## Project Structure

```
uim-iaas/
├── services/           # Microservices
│   ├── api-gateway/
│   ├── compute-service/
│   ├── storage-service/
│   ├── network-service/
│   ├── auth-service/
│   └── monitoring-service/
├── k8s/               # Kubernetes manifests
├── scripts/           # Automation scripts
├── docs/             # Documentation
├── docker-compose.yml
├── Makefile
└── README.md
```

## API Endpoints Reference

### Auth Service
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/logout` - Logout
- `GET /api/v1/auth/verify` - Verify token
- `POST /api/v1/auth/users` - Create user
- `GET /api/v1/auth/users` - List users

### Compute Service
- `GET /api/v1/compute/instances` - List instances
- `POST /api/v1/compute/instances` - Create instance
- `GET /api/v1/compute/instances/:id` - Get instance
- `DELETE /api/v1/compute/instances/:id` - Delete instance
- `POST /api/v1/compute/instances/:id/start` - Start
- `POST /api/v1/compute/instances/:id/stop` - Stop
- `GET /api/v1/compute/flavors` - List flavors

### Storage Service
- `GET /api/v1/storage/volumes` - List volumes
- `POST /api/v1/storage/volumes` - Create volume
- `POST /api/v1/storage/volumes/:id/attach` - Attach
- `POST /api/v1/storage/volumes/:id/detach` - Detach
- `GET /api/v1/storage/buckets` - List buckets
- `POST /api/v1/storage/buckets` - Create bucket

### Network Service
- `GET /api/v1/network/networks` - List networks
- `POST /api/v1/network/networks` - Create network
- `GET /api/v1/network/subnets` - List subnets
- `POST /api/v1/network/subnets` - Create subnet
- `GET /api/v1/network/security-groups` - List SGs
- `POST /api/v1/network/security-groups/:id/rules` - Add rule

### Monitoring Service
- `GET /api/v1/monitoring/metrics` - Get metrics
- `POST /api/v1/monitoring/metrics` - Record metric
- `GET /api/v1/monitoring/alerts` - List alerts
- `GET /api/v1/monitoring/dashboard` - Dashboard

## Troubleshooting

### Service won't start
```bash
# Check if port is already in use
netstat -tulpn | grep 8080

# Check service logs
make logs SERVICE=api-gateway
```

### Build fails
```bash
# Clean and rebuild
make clean
make build

# Update dependencies
dub upgrade
```

### Docker issues
```bash
# Clean Docker cache
docker system prune -a

# Rebuild from scratch
docker-compose build --no-cache
```

### Kubernetes issues
```bash
# Check pod status
kubectl get pods -n uim-iaas

# Describe pod for details
kubectl describe pod <pod-name> -n uim-iaas

# View logs
kubectl logs -f <pod-name> -n uim-iaas
```

## Next Steps

1. **Read Full Documentation:**
   - [README.md](../README.md) - Overview
   - [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture details
   - [API_EXAMPLES.md](API_EXAMPLES.md) - API examples

2. **Customize Services:**
   - Modify service code in `services/*/source/app.d`
   - Adjust Kubernetes resources in `k8s/*.yaml`
   - Update configuration in ConfigMaps

3. **Add Features:**
   - Implement database persistence
   - Add authentication middleware
   - Implement rate limiting
   - Add API versioning

4. **Production Deployment:**
   - Set up TLS/HTTPS
   - Configure secrets management
   - Implement backup strategy
   - Set up monitoring and alerting

## Support

- Issues: Create an issue in the repository
- Documentation: See `docs/` directory
- Examples: See `docs/API_EXAMPLES.md`

## License

Apache-2.0 - See LICENSE file
