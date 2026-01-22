# Compute Service

The Compute Service manages virtual machines and container instances with multi-tenancy support in the UIM IaaS platform.

## Overview

This service is part of the UIM IaaS platform and provides compute resource management capabilities. It handles the lifecycle of compute instances (VMs and containers) with full multi-tenant isolation and REST API access.

**Service Name:** `uim-iaas-compute`  
**Default Port:** 8081  
**Version:** 26.1.2 compatible

## Features

- ✅ Create, start, stop, restart, and delete compute instances
- ✅ Multi-tenant isolation with tenant-based access control
- ✅ Support for both VM and container instance types
- ✅ Instance flavors (small, medium, large, xlarge) with defined resources
- ✅ Network and volume attachment support
- ✅ Metadata key-value storage for instances
- ✅ Asynchronous instance creation and restart operations
- ✅ RESTful API with JSON responses
- ✅ Health check endpoint for monitoring

## API Endpoints

### Health Check
```
GET /health
```
Returns the service health status.

### List Instances
```
GET /api/v1/compute/instances
```
Returns all instances for the authenticated tenant.

**Headers:**
- `X-Tenant-ID`: Tenant identifier (set by API Gateway)

### Get Instance
```
GET /api/v1/compute/instances/:id
```
Returns details of a specific instance.

**Parameters:**
- `id`: Instance ID

### Create Instance
```
POST /api/v1/compute/instances
```
Creates a new compute instance.

**Request Body:**
```json
{
  "name": "my-instance",
  "type": "vm",
  "flavor": "small",
  "imageId": "ubuntu-22.04",
  "networkIds": ["net-123"],
  "volumeIds": ["vol-456"],
  "metadata": {
    "environment": "production",
    "owner": "team-a"
  }
}
```

**Response:** 201 Created with instance details.

### Delete Instance
```
DELETE /api/v1/compute/instances/:id
```
Deletes a compute instance.

**Parameters:**
- `id`: Instance ID

**Response:** 204 No Content

### Start Instance
```
POST /api/v1/compute/instances/:id/start
```
Starts a stopped instance.

### Stop Instance
```
POST /api/v1/compute/instances/:id/stop
```
Stops a running instance.

### Restart Instance
```
POST /api/v1/compute/instances/:id/restart
```
Restarts an instance.

### List Flavors
```
GET /api/v1/compute/flavors
```
Returns available instance flavors.

**Response:**
```json
{
  "flavors": [
    {"name": "small", "vcpus": 1, "ram": 1024, "disk": 10},
    {"name": "medium", "vcpus": 2, "ram": 4096, "disk": 40},
    {"name": "large", "vcpus": 4, "ram": 8192, "disk": 80},
    {"name": "xlarge", "vcpus": 8, "ram": 16384, "disk": 160}
  ]
}
```

## Instance Types

- **vm**: Virtual machine instance
- **container**: Container-based instance

## Instance Status

- `creating`: Instance is being created
- `running`: Instance is running
- `stopped`: Instance is stopped
- `restarting`: Instance is restarting
- `error`: Instance encountered an error

## Building

Build the service using DUB:
```bash
dub build
```

For release build:
```bash
dub build --build=release
```

## Running

Start the service:
```bash
dub run
```

The service will start on port **8081** by default.

## Testing

```bash
dub test
```

## Docker

Build the Docker image:
```bash
docker build -t uim-iaas-compute:latest .
```

Run the container:
```bash
docker run -p 8081:8081 uim-iaas-compute:latest
```

With environment variables:
```bash
docker run -p 8081:8081 \
  -e SERVICE_PORT=8081 \
  -e LOG_LEVEL=info \
  uim-iaas-compute:latest
```

## Configuration

The service uses the following configuration:

### Port Configuration
- Default port: **8081**
- Bind address: `0.0.0.0` (all interfaces)

### Environment Variables
- `SERVICE_PORT`: Port to listen on (default: 8081)
- `LOG_LEVEL`: Logging level (debug, info, warn, error)

## Multi-Tenancy

The service enforces tenant isolation:
- All requests must include the `X-Tenant-ID` header (typically set by the API Gateway)
- Users can only access instances belonging to their tenant
- Unauthorized access attempts return 403 Forbidden

## Dependencies

This service requires the following dependencies (managed by DUB):

- **vibe-d** ~>0.10.3: Web framework and HTTP server
- **uim-iaas:core**: Shared utilities and base classes (local path dependency)
- **uim-framework:oop** ~>26.1.2: UIM OOP framework

All dependencies are automatically resolved during build.

## Development

### Project Structure
```
compute/
├── source/
│   ├── app.d                    # Main application entry point
│   └── uim/
│       └── iaas/
│           └── compute/
│               ├── package.d    # Module exports
│               ├── entities/    # Data models
│               │   ├── instance.d
│               │   └── package.d
│               └── services/    # Business logic
│                   ├── compute.d
│                   └── package.d
├── Dockerfile
├── dub.sdl                      # DUB package configuration
└── README.md
```

## Example Usage

### Create an instance
```bash
curl -X POST http://localhost:8081/api/v1/compute/instances \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: tenant-123" \
  -d '{
    "name": "web-server-01",
    "type": "vm",
    "flavor": "medium",
    "imageId": "ubuntu-22.04",
    "metadata": {
      "app": "nginx"
    }
  }'
```

### List instances
```bash
curl http://localhost:8081/api/v1/compute/instances \
  -H "X-Tenant-ID: tenant-123"
```

### Get instance details
```bash
curl http://localhost:8081/api/v1/compute/instances/{id} \
  -H "X-Tenant-ID: tenant-123"
```

### Start an instance
```bash
curl -X POST http://localhost:8081/api/v1/compute/instances/{id}/start \
  -H "X-Tenant-ID: tenant-123"
```

### Stop an instance
```bash
curl -X POST http://localhost:8081/api/v1/compute/instances/{id}/stop \
  -H "X-Tenant-ID: tenant-123"
```

### Restart an instance
```bash
curl -X POST http://localhost:8081/api/v1/compute/instances/{id}/restart \
  -H "X-Tenant-ID: tenant-123"
```

### Delete an instance
```bash
curl -X DELETE http://localhost:8081/api/v1/compute/instances/{id} \
  -H "X-Tenant-ID: tenant-123"
```

### List available flavors
```bash
curl http://localhost:8081/api/v1/compute/flavors
```

### Check service health
```bash
curl http://localhost:8081/health
```

## License

Copyright © 2026, UI Manufaktur  
Licensed under the Apache License 2.0

See the LICENSE file in the project root for details.

## Author

Ozan Nurettin Süel

## Related Services

This service is part of the UIM IaaS platform:
- **API Gateway**: Routes and authenticates requests
- **Auth Service**: Manages authentication and tenant data
- **Network Service**: Manages virtual networks
- **Storage Service**: Manages volumes and storage
- **Monitoring Service**: Collects metrics and logs
