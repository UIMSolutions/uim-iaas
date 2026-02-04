# Object Store Service

A cloud-native object storage service built with D language and vibe.d framework, designed for Kubernetes deployment. This service provides S3-like object storage capabilities similar to SAP Object Store.

## Features

- 🚀 **RESTful API** - Complete REST API for object and container management
- 🔐 **Authentication** - Bearer token authentication for API security
- 📦 **Container Management** - Create, list, and delete storage containers
- 📁 **Object Operations** - Upload, download, delete, and list objects
- 🔑 **Service Keys** - Generate access credentials for applications
- 📊 **Metadata Support** - Track object and container metadata
- 🏥 **Health Checks** - Built-in health endpoint for monitoring
- ☸️ **Kubernetes Ready** - Full K8s manifests with auto-scaling
- 🐳 **Docker Support** - Multi-stage build for optimal image size

## Architecture

```
objectstore-service/
├── source/
│   ├── app.d                          # Main application entry point
│   └── objectstore/
│       ├── config.d                   # Configuration management
│       ├── models.d                   # Data models
│       ├── api/
│       │   ├── router.d              # REST API routes
│       │   └── auth.d                # Authentication middleware
│       └── storage/
│           └── manager.d             # Storage backend implementation
├── k8s/                               # Kubernetes manifests
├── Dockerfile                         # Container image definition
├── dub.json                          # D package configuration
└── README.md
```

## Prerequisites

- **D Compiler**: LDC 1.36.0+ or DMD 2.106.0+
- **DUB**: D package manager
- **Docker**: For containerization
- **Kubernetes**: For deployment (optional)

## Quick Start

### Local Development

1. **Install dependencies:**
```bash
cd objectstore
dub fetch
```

2. **Build the application:**
```bash
dub build
```

3. **Run the service:**
```bash
./bin/objectstore-service
```

The service will start on `http://localhost:8080`

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTP server port | `8080` |
| `STORAGE_PATH` | Object storage directory | `./data/storage` |
| `METADATA_PATH` | Metadata storage directory | `./data/metadata` |
| `AUTH_TOKEN` | Bearer token for authentication | `default-secret-token` |
| `ENABLE_AUTH` | Enable/disable authentication | `true` |
| `MAX_OBJECT_SIZE` | Maximum object size in bytes | `5368709120` (5GB) |

## API Reference

### Authentication

All API endpoints (except `/health`) require Bearer token authentication:

```bash
Authorization: Bearer <your-token>
```

### Health Check

```bash
GET /health
```

Returns service health status.

**Response:**
```json
{
  "status": "healthy",
  "service": "objectstore",
  "version": "1.0.0"
}
```

### Container Operations

#### List Containers

```bash
GET /api/v1/containers
Authorization: Bearer <token>
```

**Response:**
```json
{
  "containers": [
    {
      "name": "my-container",
      "createdAt": "2026-02-04T10:00:00Z",
      "objectCount": 5,
      "totalSize": 1024000
    }
  ]
}
```

#### Create Container

```bash
POST /api/v1/containers/{name}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "name": "my-container",
  "createdAt": "2026-02-04T10:00:00Z",
  "objectCount": 0,
  "totalSize": 0
}
```

#### Get Container Details

```bash
GET /api/v1/containers/{name}
Authorization: Bearer <token>
```

#### Delete Container

```bash
DELETE /api/v1/containers/{name}
Authorization: Bearer <token>
```

Note: Container must be empty before deletion.

### Object Operations

#### List Objects in Container

```bash
GET /api/v1/containers/{container}/objects
Authorization: Bearer <token>
```

**Response:**
```json
{
  "objects": [
    {
      "name": "document.pdf",
      "containerName": "my-container",
      "size": 1024,
      "contentType": "application/pdf",
      "createdAt": "2026-02-04T10:00:00Z",
      "lastModified": "2026-02-04T10:00:00Z",
      "etag": "abc123..."
    }
  ]
}
```

#### Upload Object

```bash
PUT /api/v1/containers/{container}/objects/{object}
Authorization: Bearer <token>
Content-Type: application/octet-stream

<binary data>
```

**Response:**
```json
{
  "name": "document.pdf",
  "containerName": "my-container",
  "size": 1024,
  "contentType": "application/pdf",
  "createdAt": "2026-02-04T10:00:00Z",
  "lastModified": "2026-02-04T10:00:00Z",
  "etag": "abc123..."
}
```

#### Download Object

```bash
GET /api/v1/containers/{container}/objects/{object}
Authorization: Bearer <token>
```

Returns the object binary data with appropriate `Content-Type` header.

#### Get Object Metadata

```bash
GET /api/v1/containers/{container}/objects/{object}/metadata
Authorization: Bearer <token>
```

#### Delete Object

```bash
DELETE /api/v1/containers/{container}/objects/{object}
Authorization: Bearer <token>
```

### Service Key Operations

#### Create Service Key

```bash
POST /api/v1/containers/{name}/keys
Authorization: Bearer <token>
Content-Type: application/json

{
  "keyName": "app-key-1"
}
```

**Response:**
```json
{
  "keyName": "app-key-1",
  "containerName": "my-container",
  "accessToken": "generated-uuid-token",
  "endpoint": "http://objectstore-service/api/v1",
  "createdAt": "2026-02-04T10:00:00Z"
}
```

#### Get Service Key

```bash
GET /api/v1/containers/{name}/keys/{keyname}
Authorization: Bearer <token>
```

#### Delete Service Key

```bash
DELETE /api/v1/containers/{name}/keys/{keyname}
Authorization: Bearer <token>
```

## Docker Deployment

### Build Image

```bash
docker build -t objectstore-service:latest .
```

### Run Container

```bash
docker run -d \
  -p 8080:8080 \
  -e AUTH_TOKEN="your-secret-token" \
  -v $(pwd)/data:/app/data \
  objectstore-service:latest
```

## Kubernetes Deployment

### Deploy to Kubernetes

1. **Create namespace and resources:**
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/configmap.yaml
```

2. **Create secret (update token first!):**
```bash
# Edit k8s/secret.yaml to set your AUTH_TOKEN
kubectl apply -f k8s/secret.yaml
```

3. **Deploy service:**
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
```

4. **Setup ingress (optional):**
```bash
# Edit k8s/ingress.yaml to set your domain
kubectl apply -f k8s/ingress.yaml
```

### Verify Deployment

```bash
# Check pods
kubectl get pods -n objectstore

# Check service
kubectl get svc -n objectstore

# View logs
kubectl logs -f deployment/objectstore-service -n objectstore

# Port forward for testing
kubectl port-forward svc/objectstore-service 8080:80 -n objectstore
```

### Apply All Manifests at Once

```bash
kubectl apply -f k8s/
```

## Usage Examples

### Using cURL

```bash
# Set token
TOKEN="your-secret-token"

# Create a container
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/v1/containers/test-bucket

# Upload a file
curl -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: text/plain" \
  --data-binary @myfile.txt \
  http://localhost:8080/api/v1/containers/test-bucket/objects/myfile.txt

# List objects
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/v1/containers/test-bucket/objects

# Download object
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/v1/containers/test-bucket/objects/myfile.txt \
  -o downloaded.txt

# Create service key
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"keyName":"my-app-key"}' \
  http://localhost:8080/api/v1/containers/test-bucket/keys
```

### Using Python

```python
import requests

BASE_URL = "http://localhost:8080/api/v1"
TOKEN = "your-secret-token"
headers = {"Authorization": f"Bearer {TOKEN}"}

# Create container
response = requests.post(
    f"{BASE_URL}/containers/test-bucket",
    headers=headers
)
print(response.json())

# Upload object
with open("myfile.txt", "rb") as f:
    response = requests.put(
        f"{BASE_URL}/containers/test-bucket/objects/myfile.txt",
        headers={**headers, "Content-Type": "text/plain"},
        data=f
    )
print(response.json())

# List objects
response = requests.get(
    f"{BASE_URL}/containers/test-bucket/objects",
    headers=headers
)
print(response.json())

# Download object
response = requests.get(
    f"{BASE_URL}/containers/test-bucket/objects/myfile.txt",
    headers=headers
)
with open("downloaded.txt", "wb") as f:
    f.write(response.content)
```

## Monitoring

### Prometheus Metrics

The service exposes metrics at `/metrics` endpoint (when metrics are enabled).

### Health Probes

- **Liveness**: `GET /health`
- **Readiness**: `GET /health`

## Security Considerations

1. **Change default token**: Always set a strong `AUTH_TOKEN` in production
2. **Use HTTPS**: Deploy behind TLS termination (ingress with cert-manager)
3. **Network policies**: Restrict pod-to-pod communication in K8s
4. **RBAC**: Use Kubernetes RBAC for cluster access control
5. **Storage encryption**: Consider encrypting the persistent volume
6. **Secrets management**: Use Kubernetes secrets or external secret managers

## Performance Tuning

### Horizontal Scaling

The service includes HPA configuration that scales based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)
- Min replicas: 2, Max replicas: 10

### Storage Performance

- Use SSD-backed storage classes for better I/O
- Consider object storage backends (S3, MinIO) for production
- Implement caching layer for frequently accessed objects

## Limitations

- Maximum object size: 5GB (configurable)
- Storage backend: Filesystem-based (can be extended)
- Authentication: Simple bearer token (can add OAuth2/OIDC)
- No built-in replication (relies on K8s/storage layer)

## Extending the Service

### Adding S3 Backend

Modify `objectstore.storage.manager` to support S3-compatible storage:

```d
// Add AWS SDK or MinIO client
// Implement S3StorageBackend class
// Switch between filesystem and S3 based on config
```

### Adding Multi-tenancy

Implement namespace/tenant isolation:

```d
// Add tenant field to containers
// Validate tenant access in middleware
// Separate storage paths per tenant
```

## Troubleshooting

### Service won't start

```bash
# Check logs
kubectl logs deployment/objectstore-service -n objectstore

# Common issues:
# - Missing persistent volume
# - Incorrect secret/config
# - Port already in use
```

### Authentication failures

```bash
# Verify token
kubectl get secret objectstore-secret -n objectstore -o jsonpath='{.data.AUTH_TOKEN}' | base64 -d

# Test without auth
curl http://localhost:8080/health
```

### Storage issues

```bash
# Check PVC status
kubectl get pvc -n objectstore

# Check available space
kubectl exec -it deployment/objectstore-service -n objectstore -- df -h /app/data
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
- GitHub Issues: [project-url]/issues
- Documentation: [project-url]/docs

## References

- [vibe.d Documentation](https://vibed.org/)
- [D Language](https://dlang.org/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [SAP Object Store Service](https://help.sap.com/)
