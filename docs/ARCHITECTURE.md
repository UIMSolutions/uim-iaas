# UIM IaaS Platform Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Load Balancer                            │
│                    (Kubernetes Service)                          │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway                                 │
│                       (Port 8080)                                │
│  - Request routing                                               │
│  - Service discovery                                             │
│  - Health monitoring                                             │
└──┬────────┬────────┬────────┬────────┬──────────────────────────┘
   │        │        │        │        │
   ▼        ▼        ▼        ▼        ▼
┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐
│Auth  │ │Comp  │ │Store │ │Net   │ │Monitor   │
│8084  │ │8081  │ │8082  │ │8083  │ │8085      │
└──────┘ └──────┘ └──────┘ └──────┘ └──────────┘
```

## Microservices Architecture

### 1. API Gateway (Port 8080)
**Responsibility:** Central entry point and request router

**Key Features:**
- Routes requests to backend services
- Service health monitoring
- Request/response proxying
- Platform status aggregation

**API Endpoints:**
- `GET /health` - Gateway health check
- `GET /api/v1/status` - Platform-wide status
- `ANY /api/v1/{service}/*` - Proxy to services

### 2. Auth Service (Port 8084)
**Responsibility:** Authentication and authorization

**Key Features:**
- User authentication (username/password)
- Session management with tokens
- API key generation
- Role-based access control (admin, user, viewer)
- Token verification

**API Endpoints:**
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/logout` - User logout
- `GET /api/v1/auth/verify` - Token verification
- `POST /api/v1/auth/users` - Create user
- `POST /api/v1/auth/api-keys` - Generate API key

**Default Credentials:**
- Username: `admin`
- Password: `admin123`

### 3. Compute Service (Port 8081)
**Responsibility:** Virtual machine and container management

**Key Features:**
- Instance lifecycle management (create, start, stop, delete)
- Multiple instance flavors (small, medium, large, xlarge)
- Instance status tracking
- Metadata support
- Network and volume attachment

**API Endpoints:**
- `GET /api/v1/compute/instances` - List instances
- `POST /api/v1/compute/instances` - Create instance
- `POST /api/v1/compute/instances/:id/start` - Start instance
- `POST /api/v1/compute/instances/:id/stop` - Stop instance
- `GET /api/v1/compute/flavors` - List available flavors

**Instance Flavors:**
| Flavor  | vCPUs | RAM (MB) | Disk (GB) |
|---------|-------|----------|-----------|
| small   | 1     | 1024     | 10        |
| medium  | 2     | 4096     | 40        |
| large   | 4     | 8192     | 80        |
| xlarge  | 8     | 16384    | 160       |

### 4. Storage Service (Port 8082)
**Responsibility:** Block and object storage management

**Key Features:**
- Block storage volumes
- Volume attach/detach to instances
- Volume snapshots
- Object storage buckets
- Storage quota tracking

**API Endpoints:**
- `GET /api/v1/storage/volumes` - List volumes
- `POST /api/v1/storage/volumes` - Create volume
- `POST /api/v1/storage/volumes/:id/attach` - Attach volume
- `POST /api/v1/storage/volumes/:id/snapshot` - Create snapshot
- `GET /api/v1/storage/buckets` - List buckets
- `POST /api/v1/storage/buckets` - Create bucket

### 5. Network Service (Port 8083)
**Responsibility:** Virtual networking and security

**Key Features:**
- Virtual network creation (VPC)
- Subnet management with DHCP
- Security groups and firewall rules
- Network isolation
- DNS configuration

**API Endpoints:**
- `GET /api/v1/network/networks` - List networks
- `POST /api/v1/network/networks` - Create network
- `GET /api/v1/network/subnets` - List subnets
- `POST /api/v1/network/subnets` - Create subnet
- `GET /api/v1/network/security-groups` - List security groups
- `POST /api/v1/network/security-groups` - Create security group
- `POST /api/v1/network/security-groups/:id/rules` - Add rule

### 6. Monitoring Service (Port 8085)
**Responsibility:** Metrics collection and alerting

**Key Features:**
- Metrics collection (gauge, counter, histogram)
- Alert management with severity levels
- Service health tracking
- Dashboard with aggregated statistics
- Time-series data storage

**API Endpoints:**
- `GET /api/v1/monitoring/metrics` - Get metrics
- `POST /api/v1/monitoring/metrics` - Record metric
- `GET /api/v1/monitoring/alerts` - List alerts
- `POST /api/v1/monitoring/alerts` - Create alert
- `GET /api/v1/monitoring/dashboard` - Get dashboard

## Communication Flow

### Typical Request Flow

1. **Client Request**
   ```
   Client → Load Balancer → API Gateway (Port 8080)
   ```

2. **Authentication** (if required)
   ```
   API Gateway → Auth Service (Port 8084) → Verify Token
   ```

3. **Service Request**
   ```
   API Gateway → Target Service (8081-8085) → Process Request
   ```

4. **Response**
   ```
   Target Service → API Gateway → Client
   ```

### Inter-Service Communication

Services communicate via HTTP REST APIs:
- **Synchronous:** HTTP requests for immediate responses
- **Health Checks:** Each service exposes `/health` endpoint
- **Service Discovery:** Services are accessible by DNS name in Kubernetes

## Deployment Architecture

### Kubernetes Deployment

```
Namespace: uim-iaas
│
├── Deployments (with replicas)
│   ├── api-gateway (2 replicas)
│   ├── auth-service (2 replicas)
│   ├── compute-service (2 replicas)
│   ├── storage-service (2 replicas)
│   ├── network-service (2 replicas)
│   └── monitoring-service (1 replica)
│
├── Services (ClusterIP + LoadBalancer)
│   ├── api-gateway (LoadBalancer, Port 80→8080)
│   ├── auth-service (ClusterIP, Port 8084)
│   ├── compute-service (ClusterIP, Port 8081)
│   ├── storage-service (ClusterIP, Port 8082)
│   ├── network-service (ClusterIP, Port 8083)
│   └── monitoring-service (ClusterIP, Port 8085)
│
└── ConfigMaps
    └── uim-iaas-config
```

### Resource Requirements

| Service          | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------------------|-------------|-----------|----------------|--------------|
| API Gateway      | 100m        | 500m      | 128Mi          | 256Mi        |
| Auth Service     | 100m        | 500m      | 128Mi          | 256Mi        |
| Compute Service  | 200m        | 1000m     | 256Mi          | 512Mi        |
| Storage Service  | 200m        | 1000m     | 256Mi          | 512Mi        |
| Network Service  | 100m        | 500m      | 128Mi          | 256Mi        |
| Monitoring       | 100m        | 500m      | 256Mi          | 512Mi        |

## Technology Stack

### Core Technologies
- **Language:** D (dlang)
- **Web Framework:** vibe.d
- **Compiler:** LDC2 (LLVM D Compiler)
- **Package Manager:** DUB

### Container & Orchestration
- **Containerization:** Docker
- **Orchestration:** Kubernetes
- **Base Image:** dlang2/ldc-ubuntu

### Protocols & Formats
- **API Protocol:** REST over HTTP/HTTPS
- **Data Format:** JSON
- **Authentication:** Bearer Token

## Scalability

### Horizontal Scaling
All services support horizontal scaling:
- **API Gateway:** Scale to handle more traffic
- **Backend Services:** Scale based on workload
- **Monitoring:** Single instance recommended (stores metrics in memory)

### Kubernetes Scaling
```bash
# Scale compute service to 5 replicas
kubectl scale deployment compute-service -n uim-iaas --replicas=5

# Autoscaling
kubectl autoscale deployment compute-service -n uim-iaas \
  --cpu-percent=70 --min=2 --max=10
```

## High Availability

### Service Redundancy
- Multiple replicas for each service
- Load balancing across replicas
- Health checks with automatic restart
- Rolling updates with zero downtime

### Health Monitoring
Each service implements:
- **Liveness Probe:** Checks if service is alive
- **Readiness Probe:** Checks if service can handle requests
- **Health Endpoint:** `/health` returns service status

## Security Considerations

### Authentication
- Token-based authentication
- API keys for programmatic access
- Role-based access control

### Network Security
- Services only accessible within cluster (ClusterIP)
- API Gateway as single external entry point
- Security groups for instance-level firewalls

### Best Practices
- Use TLS/HTTPS in production
- Rotate API keys regularly
- Implement rate limiting
- Store secrets in Kubernetes Secrets (not ConfigMaps)
- Enable network policies

## Monitoring & Observability

### Metrics Collection
- Service-level metrics
- Resource utilization
- Request/response times
- Error rates

### Alerting
- Critical: Immediate attention required
- Warning: Should be addressed soon
- Info: Informational only

### Logging
- Structured logging via vibe.d
- Log levels: debug, info, warn, error
- Kubernetes log aggregation

## Future Enhancements

### Phase 2
- [ ] Database persistence (PostgreSQL, Redis)
- [ ] Message queue (RabbitMQ, Kafka)
- [ ] Service mesh (Istio, Linkerd)
- [ ] Distributed tracing (Jaeger)

### Phase 3
- [ ] Multi-tenant support
- [ ] Billing and metering
- [ ] Advanced scheduling
- [ ] Auto-scaling policies

### Phase 4
- [ ] Web UI dashboard
- [ ] CLI client
- [ ] Terraform provider
- [ ] OpenStack compatibility layer

## Troubleshooting

### Common Issues

**Service won't start:**
```bash
# Check logs
kubectl logs -n uim-iaas -l app=compute-service

# Check events
kubectl get events -n uim-iaas
```

**Cannot connect to service:**
```bash
# Check service endpoints
kubectl get endpoints -n uim-iaas

# Port forward for testing
kubectl port-forward -n uim-iaas svc/compute-service 8081:8081
```

**High memory usage:**
```bash
# Check resource usage
kubectl top pods -n uim-iaas

# Adjust limits in deployment YAML
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

Apache-2.0 License - See LICENSE file for details
