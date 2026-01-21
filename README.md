# UIM IaaS Platform

A microservices-based Infrastructure-as-a-Service (IaaS) platform built with vibe.d and D language, designed for deployment on Kubernetes.

## Overview

UIM IaaS Platform provides a comprehensive set of microservices for managing cloud infrastructure resources:

- **API Gateway** (Port 8080) - Central entry point routing requests to backend services
- **Compute Service** (Port 8081) - Manages virtual machines and container instances
- **Storage Service** (Port 8082) - Handles block storage volumes and object storage buckets
- **Network Service** (Port 8083) - Manages virtual networks, subnets, and security groups
- **Auth Service** (Port 8084) - Handles authentication, authorization, and API keys
- **Monitoring Service** (Port 8085) - Collects metrics, alerts, and health check data

## Architecture

The platform follows a microservices architecture where:
- Each service is independently deployable
- Services communicate via REST APIs
- The API Gateway provides a unified interface
- All services include health checks and are Kubernetes-ready

## Quick Start

### Prerequisites

- D language compiler (ldc2 recommended)
- DUB package manager
- Docker
- Kubernetes cluster (for production deployment)

### Local Development

Run all services locally:
```bash
chmod +x scripts/*.sh
./scripts/dev-run.sh
```

Or run individual services:
```bash
cd services/api-gateway
dub run
```

### Docker Compose

Run all services using Docker Compose:
```bash
docker-compose up --build
```

### Kubernetes Deployment

1. Build Docker images:
```bash
./scripts/build-all.sh
```

2. Deploy to Kubernetes:
```bash
./scripts/deploy-k8s.sh
```

3. Access the API Gateway:
```bash
kubectl port-forward -n uim-iaas svc/api-gateway 8080:80
```

4. Test the platform:
```bash
curl http://localhost:8080/api/v1/status
```

### Undeploy from Kubernetes

```bash
./scripts/undeploy-k8s.sh
```

## API Documentation

### Authentication

Login to get a token:
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

Use the token in subsequent requests:
```bash
curl http://localhost:8080/api/v1/compute/instances \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Compute Service

Create an instance:
```bash
curl -X POST http://localhost:8080/api/v1/compute/instances \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-vm",
    "type": "vm",
    "flavor": "medium",
    "imageId": "ubuntu-22.04"
  }'
```

List instances:
```bash
curl http://localhost:8080/api/v1/compute/instances
```

### Storage Service

Create a volume:
```bash
curl -X POST http://localhost:8080/api/v1/storage/volumes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-volume",
    "sizeGB": 100
  }'
```

### Network Service

Create a network:
```bash
curl -X POST http://localhost:8080/api/v1/network/networks \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-network",
    "cidr": "10.0.0.0/16"
  }'
```

### Monitoring Service

Get platform dashboard:
```bash
curl http://localhost:8080/api/v1/monitoring/dashboard
```

## Project Structure

```
uim-iaas/
├── services/
│   ├── api-gateway/
│   ├── compute-service/
│   ├── storage-service/
│   ├── network-service/
│   ├── auth-service/
│   └── monitoring-service/
├── k8s/
│   ├── namespace.yaml
│   ├── api-gateway.yaml
│   ├── compute-service.yaml
│   ├── storage-service.yaml
│   ├── network-service.yaml
│   ├── auth-service.yaml
│   └── monitoring-service.yaml
├── scripts/
│   ├── build-all.sh
│   ├── deploy-k8s.sh
│   ├── undeploy-k8s.sh
│   └── dev-run.sh
├── docker-compose.yml
└── README.md
```

## Service Details

### API Gateway
- Routes requests to appropriate microservices
- Provides service discovery
- Health checks all backend services
- Exposes unified API at `/api/v1/*`

### Compute Service
- Manages VM and container lifecycle
- Supports multiple instance flavors (small, medium, large, xlarge)
- Instance operations: create, delete, start, stop, restart

### Storage Service
- Block storage volumes with attach/detach capabilities
- Object storage buckets
- Volume snapshots
- Storage quota management

### Network Service
- Virtual network management
- Subnet configuration with DHCP
- Security groups with ingress/egress rules
- Network isolation

### Auth Service
- User authentication and session management
- API key generation and management
- Role-based access control (admin, user, viewer)
- Token-based authentication

### Monitoring Service
- Metrics collection (gauge, counter, histogram)
- Alert management with severity levels
- Service health tracking
- Dashboard with aggregated statistics

## Configuration

### Environment Variables

All services support the following environment variables:
- `PORT` - Service port (default: service-specific)
- `LOG_LEVEL` - Logging level (info, debug, warn, error)

### Kubernetes Configuration

ConfigMaps are located in `k8s/namespace.yaml` and can be modified to adjust platform settings.

## Development

### Building Individual Services

```bash
cd services/compute-service
dub build --build=release
```

### Running Tests

```bash
cd services/compute-service
dub test
```

## License

Apache-2.0

## Author

Ozan Nurettin Süel - UI Manufaktur

Copyright © 2026, UI Manufaktur
