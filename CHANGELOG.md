# Changelog

All notable changes to the UIM IaaS Platform project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-21

### Added - Multi-Tenancy Support

#### Core Features
- **Complete multi-tenancy architecture** across all 6 microservices
- **Tenant management** with full CRUD operations in Auth Service
- **Header-based tenant propagation** via X-Tenant-ID header
- **Automatic tenant filtering** in all list operations
- **Tenant ownership verification** in all modify/delete operations
- **Cross-tenant access prevention** with security checks

#### Auth Service Enhancements
- New `Tenant` struct with id, name, description, active flag, timestamps, and metadata
- Tenant CRUD API endpoints:
  - `GET /api/v1/auth/tenants` - List all tenants
  - `GET /api/v1/auth/tenants/:id` - Get tenant details
  - `POST /api/v1/auth/tenants` - Create tenant
  - `PUT /api/v1/auth/tenants/:id` - Update tenant
  - `DELETE /api/v1/auth/tenants/:id` - Delete tenant
- Added `tenantId` field to User and Session structs
- Default "default" tenant created on startup
- Existing users assigned to default tenant

#### API Gateway Enhancements
- Token verification with Auth Service before proxying requests
- Tenant context extraction from verified tokens
- Automatic injection of X-Tenant-ID header to backend service requests
- Enhanced `proxyRequest()` method with tenant context handling

#### Compute Service Enhancements
- Added `tenantId` field to Instance struct
- `getTenantIdFromRequest()` helper function to extract tenant from headers
- Tenant filtering in `listInstances()` endpoint
- Tenant assignment in `createInstance()` operation
- Tenant ownership verification in get/update/delete operations
- All instance operations now tenant-scoped

#### Storage Service Enhancements
- Added `tenantId` field to Volume struct
- Added `tenantId` field to Bucket struct
- Tenant filtering in list volumes and list buckets endpoints
- Tenant ownership verification for all volume/bucket operations
- Automatic tenant assignment when creating volumes/buckets

#### Network Service Enhancements
- Added `tenantId` field to Network struct
- Added `tenantId` field to Subnet struct
- Added `tenantId` field to SecurityGroup struct
- Tenant filtering in all list endpoints
- Tenant ownership verification for all network operations
- Automatic tenant assignment when creating network resources

#### Monitoring Service Enhancements
- Added `tenantId` field to Metric struct
- Added `tenantId` field to Alert struct
- Added `tenantId` field to HealthCheck struct
- Tenant filtering in getMetrics, listAlerts, and getDashboard endpoints
- Tenant-scoped metric recording and alert creation

#### Documentation
- **NEW:** `docs/MULTI_TENANCY.md` - Comprehensive 400+ line multi-tenancy guide
  - Architecture overview with diagrams
  - Complete tenant management API documentation
  - Multi-tenant workflow examples
  - Security model explanation
  - Best practices and troubleshooting
  - Migration guide from single-tenant
  - Future enhancement roadmap
- Updated `README.md` with multi-tenancy features
- Updated `docs/ARCHITECTURE.md` with tenant isolation flow
- Updated `docs/API_EXAMPLES.md` with multi-tenant examples
- Updated `PROJECT_SUMMARY.md` with multi-tenancy architecture section

#### Testing
- **NEW:** `scripts/test-multitenancy.sh` - Automated multi-tenancy test script
  - Creates 2 tenants with separate users
  - Creates isolated resources for each tenant
  - Verifies tenant isolation across all services
  - Tests cross-tenant access prevention
  - Provides comprehensive test summary

### Changed
- All service endpoints now tenant-aware
- API Gateway now verifies tokens before proxying
- All data structures include tenantId field
- All list operations filter by tenant
- All create operations assign tenant automatically
- All modify/delete operations verify tenant ownership

### Security
- Enhanced security with tenant-based access control
- Cross-tenant access automatically prevented
- Resource ownership verified on all operations
- Tenant context validated on every request

## [1.0.0] - 2025-01-20

### Added - Initial Release

#### Core Services
- API Gateway (Port 8080) - Request routing and service discovery
- Auth Service (Port 8084) - Authentication and authorization
- Compute Service (Port 8081) - VM and container management
- Storage Service (Port 8082) - Block and object storage
- Network Service (Port 8083) - Virtual networking
- Monitoring Service (Port 8085) - Metrics and alerting

#### Features
- RESTful API with JSON responses
- Token-based authentication
- Role-based access control (admin, user, viewer)
- Health checks for all services
- Docker containerization
- Kubernetes deployment manifests
- Docker Compose support
- Comprehensive documentation

#### Infrastructure
- Kubernetes namespace and ConfigMap
- Service deployments with proper resource limits
- LoadBalancer for API Gateway
- ClusterIP services for internal communication
- Horizontal Pod Autoscaler ready
- Rolling update strategy

#### Documentation
- README.md - Main documentation
- docs/QUICKSTART.md - Getting started guide
- docs/ARCHITECTURE.md - Technical architecture
- docs/API_EXAMPLES.md - API usage examples
- PROJECT_SUMMARY.md - Project overview

#### Automation
- `scripts/build-all.sh` - Build all Docker images
- `scripts/deploy-k8s.sh` - Deploy to Kubernetes
- `scripts/undeploy-k8s.sh` - Remove from Kubernetes
- `scripts/dev-run.sh` - Local development mode
- Makefile for common tasks

#### Developer Experience
- Clean project structure
- D language with vibe.d framework
- Consistent API patterns across services
- Comprehensive examples
- Easy local development setup

---

## Legend
- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
