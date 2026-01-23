# UIM IaaS Monitoring Service

## Overview

The **UIM IaaS Monitoring Service** is a comprehensive multi-tenant monitoring and observability platform designed to collect, store, and analyze metrics, alerts, and health checks across distributed infrastructure services. Built with the D programming language and the vibe.d framework, it provides real-time insights into system health and performance.

## NAF v4 Architecture Alignment

This service follows the **NATO Architecture Framework (NAF) Version 4** principles, ensuring standardized architecture documentation and interoperability.

### NAF v4 Views Implemented

#### NOV-1: High-Level Operational Concept
The Monitoring Service operates as a centralized observability hub that:
- Collects metrics from distributed IaaS services (compute, storage, network, auth)
- Manages alerting based on configurable thresholds
- Tracks service health across the entire infrastructure
- Provides a unified dashboard for operational visibility

#### NOV-2: Operational Node Connectivity
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Auth      │────▶│ Monitoring  │◀────│  Compute    │
│  Service    │     │   Service   │     │  Service    │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │             │
              ┌─────▼─────┐  ┌───▼────┐
              │  Storage  │  │ Network│
              │  Service  │  │ Service│
              └───────────┘  └────────┘
```

#### NSV-1: Systems Interface Description
The Monitoring Service exposes RESTful HTTP interfaces for:
- Metrics ingestion and retrieval
- Alert management
- Health check recording
- Dashboard aggregation

#### NSV-4: Systems Functionality Description

**Core Functions:**
1. **Metric Collection**: Time-series data ingestion with labels and metadata
2. **Alert Management**: Creation, tracking, and resolution of system alerts
3. **Health Monitoring**: Service availability and performance tracking
4. **Aggregation**: Statistical analysis (min, max, avg, sum) of metrics
5. **Multi-tenancy**: Isolated data per tenant with secure access control

## Architecture

### Entity-Service Pattern

The service follows a clean separation between data models (entities) and business logic (services):

```
┌─────────────────────────────────────────────────────┐
│                  Monitoring Service                 │
├─────────────────────────────────────────────────────┤
│  Entities Layer                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │ MetricEntity │  │ AlertEntity  │  │ HealthCh │ │
│  │              │  │              │  │ eckEntity│ │
│  │ - name       │  │ - severity   │  │          │ │
│  │ - value      │  │ - message    │  │ - status │ │
│  │ - tenantId   │  │ - active     │  │ - service│ │
│  │ - timestamp  │  │ - source     │  │          │ │
│  │ - labels     │  │              │  │          │ │
│  └──────────────┘  └──────────────┘  └──────────┘ │
├─────────────────────────────────────────────────────┤
│  Service Layer                                      │
│  ┌────────────────────────────────────────────────┐│
│  │         MonitoringService                      ││
│  │                                                ││
│  │  + recordMetric()                             ││
│  │  + getMetrics()                               ││
│  │  + getMetricsByName()                         ││
│  │  + createAlert()                              ││
│  │  + resolveAlert()                             ││
│  │  + recordHealthCheck()                        ││
│  │  + getDashboard()                             ││
│  └────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

## UML Diagrams

### Class Diagram

```plantuml
@startuml
!theme plain

package "uim.iaas.monitoring.entities" {
    class IaasEntity {
        +string id
    }
    
    class MetricEntity {
        -string _name
        -string _tenantId
        -string _type
        -double _value
        -string[string] _labels
        -long _timestamp
        +name() : string
        +name(string) : void
        +tenantId() : string
        +type() : string
        +value() : double
        +labels() : string[string]
        +timestamp() : long
    }
    
    class AlertEntity {
        -string _name
        -string _tenantId
        -string _severity
        -string _message
        -string _source
        -bool _active
        -long _triggeredAt
        -long _resolvedAt
        +name() : string
        +severity() : string
        +message() : string
        +active() : bool
        +triggeredAt() : long
        +resolvedAt() : long
    }
    
    class HealthCheckEntity {
        -string _service
        -string _tenantId
        -string _status
        -long _responseTime
        -string _message
        -long _timestamp
        +service() : string
        +status() : string
        +responseTime() : long
        +timestamp() : long
    }
    
    IaasEntity <|-- MetricEntity
    IaasEntity <|-- AlertEntity
    IaasEntity <|-- HealthCheckEntity
}

package "uim.iaas.monitoring.services" {
    class MonitoringService {
        -MetricEntity[] metrics
        -AlertEntity[string] alerts
        -HealthCheckEntity[string] healthChecks
        +setupRoutes(URLRouter) : void
        +healthCheck(HTTPServerRequest, HTTPServerResponse) : void
        +getMetrics(HTTPServerRequest, HTTPServerResponse) : void
        +recordMetric(HTTPServerRequest, HTTPServerResponse) : void
        +getMetricsByName(HTTPServerRequest, HTTPServerResponse) : void
        +listAlerts(HTTPServerRequest, HTTPServerResponse) : void
        +createAlert(HTTPServerRequest, HTTPServerResponse) : void
        +resolveAlert(HTTPServerRequest, HTTPServerResponse) : void
        +listHealthChecks(HTTPServerRequest, HTTPServerResponse) : void
        +recordHealthCheck(HTTPServerRequest, HTTPServerResponse) : void
        +getDashboard(HTTPServerRequest, HTTPServerResponse) : void
        -getTenantIdFromRequest(HTTPServerRequest) : string
        -serializeMetric(MetricEntity) : Json
        -serializeAlert(AlertEntity) : Json
        -serializeHealthCheck(HealthCheckEntity) : Json
    }
    
    MonitoringService "1" o-- "*" MetricEntity : manages
    MonitoringService "1" o-- "*" AlertEntity : manages
    MonitoringService "1" o-- "*" HealthCheckEntity : manages
}

@enduml
```

### Sequence Diagram: Recording a Metric

```plantuml
@startuml
!theme plain

actor Client
participant "API Gateway" as Gateway
participant "MonitoringService" as Service
participant "MetricEntity" as Entity
database "In-Memory Store" as Store

Client -> Gateway: POST /api/v1/monitoring/metrics\n{name, value, labels}
activate Gateway

Gateway -> Service: recordMetric(req, res)
activate Service

Service -> Service: getTenantIdFromRequest(req)
Service -> Entity: new MetricEntity()
activate Entity

Service -> Entity: Set properties\n(name, value, tenantId, timestamp)
Service -> Entity: Set labels
Entity --> Service: metric
deactivate Entity

Service -> Store: metrics ~= metric
Service -> Service: Keep last 10000 metrics
Service -> Service: serializeMetric(metric)
Service --> Gateway: 201 Created\n{metric JSON}
deactivate Service

Gateway --> Client: 201 Created\n{metric JSON}
deactivate Gateway

@enduml
```

### Sequence Diagram: Dashboard Retrieval

```plantuml
@startuml
!theme plain

actor User
participant "Web Client" as Client
participant "MonitoringService" as Service
database "In-Memory Store" as Store

User -> Client: Request Dashboard
Client -> Service: GET /api/v1/monitoring/dashboard\nX-Tenant-ID: tenant-123
activate Service

Service -> Service: getTenantIdFromRequest(req)
Service -> Store: Query active alerts\nfor tenant
Store --> Service: alerts[]

Service -> Service: Count alerts by severity\n(critical, warning, info)

Service -> Store: Query health checks\nfor tenant
Store --> Service: healthChecks[]

Service -> Service: Count services by status\n(healthy, degraded, unhealthy)

Service -> Store: Query recent metrics\n(last hour) for tenant
Store --> Service: metrics[]

Service -> Service: Calculate metrics count

Service --> Client: 200 OK\n{dashboard: {...}}
deactivate Service

Client --> User: Display Dashboard\nwith aggregated data

@enduml
```

### State Diagram: Alert Lifecycle

```plantuml
@startuml
!theme plain

[*] --> Active : createAlert()

Active : active = true
Active : triggeredAt = timestamp
Active : resolvedAt = 0

Active --> Resolved : resolveAlert()

Resolved : active = false
Resolved : resolvedAt = timestamp

Resolved --> [*]

@enduml
```

### Component Diagram

```plantuml
@startuml
!theme plain

package "Monitoring Service" {
    component [app.d] as App
    
    package "Entities" {
        component [MetricEntity]
        component [AlertEntity]
        component [HealthCheckEntity]
    }
    
    package "Services" {
        component [MonitoringService]
    }
    
    App ..> MonitoringService : uses
    MonitoringService ..> MetricEntity : manages
    MonitoringService ..> AlertEntity : manages
    MonitoringService ..> HealthCheckEntity : manages
}

component [vibe.d] as Vibe
component [UIM Core] as Core

App --> Vibe : HTTP Server
MonitoringService --> Vibe : URLRouter
MetricEntity --|> Core : extends IaasEntity
AlertEntity --|> Core : extends IaasEntity
HealthCheckEntity --|> Core : extends IaasEntity

cloud "External Services" {
    component [Compute Service]
    component [Storage Service]
    component [Network Service]
}

[Compute Service] --> App : POST metrics
[Storage Service] --> App : POST metrics
[Network Service] --> App : POST health checks

@enduml
```

## API Endpoints

### Health Check
```http
GET /health
```
Returns service health status.

### Metrics

#### Record a Metric
```http
POST /api/v1/monitoring/metrics
Content-Type: application/json
X-Tenant-ID: your-tenant-id

{
  "name": "cpu_usage",
  "type": "gauge",
  "value": 75.5,
  "labels": {
    "host": "server-01",
    "region": "us-east"
  }
}
```

#### Get All Metrics
```http
GET /api/v1/monitoring/metrics?start=1640995200&end=1641081600
X-Tenant-ID: your-tenant-id
```

#### Get Metrics by Name (with Aggregations)
```http
GET /api/v1/monitoring/metrics/cpu_usage
X-Tenant-ID: your-tenant-id
```

Response includes min, max, avg, and sum:
```json
{
  "name": "cpu_usage",
  "metrics": [...],
  "count": 100,
  "aggregations": {
    "min": 45.2,
    "max": 95.8,
    "avg": 72.3,
    "sum": 7230.0
  }
}
```

### Alerts

#### Create an Alert
```http
POST /api/v1/monitoring/alerts
Content-Type: application/json
X-Tenant-ID: your-tenant-id

{
  "name": "High CPU Alert",
  "severity": "critical",
  "message": "CPU usage exceeded 90%",
  "source": "compute-service"
}
```

#### List Alerts
```http
GET /api/v1/monitoring/alerts?active=true
X-Tenant-ID: your-tenant-id
```

#### Get Alert by ID
```http
GET /api/v1/monitoring/alerts/{alert-id}
X-Tenant-ID: your-tenant-id
```

#### Resolve an Alert
```http
POST /api/v1/monitoring/alerts/{alert-id}/resolve
X-Tenant-ID: your-tenant-id
```

### Health Checks

#### Record a Health Check
```http
POST /api/v1/monitoring/health-checks
Content-Type: application/json
X-Tenant-ID: your-tenant-id

{
  "service": "compute-service",
  "status": "healthy",
  "responseTime": 120,
  "message": "All systems operational"
}
```

#### List Health Checks
```http
GET /api/v1/monitoring/health-checks
X-Tenant-ID: your-tenant-id
```

### Dashboard

#### Get Dashboard
```http
GET /api/v1/monitoring/dashboard
X-Tenant-ID: your-tenant-id
```

Returns aggregated dashboard data:
```json
{
  "dashboard": {
    "timestamp": 1640995200,
    "alerts": {
      "critical": 2,
      "warning": 5,
      "info": 3,
      "total": 10
    },
    "services": {
      "healthy": 4,
      "degraded": 1,
      "unhealthy": 0,
      "total": 5
    },
    "metrics": {
      "total": 10000,
      "lastHour": 1543
    }
  }
}
```

## Multi-Tenancy

The Monitoring Service implements **tenant isolation** to ensure data segregation:

- **Tenant Identification**: Via `X-Tenant-ID` HTTP header
- **Data Filtering**: All queries filter by tenant ID automatically
- **Default Tenant**: Falls back to "default" if no header provided
- **Isolation Guarantee**: Metrics, alerts, and health checks are scoped per tenant

### Example Multi-Tenant Usage

Tenant A:
```bash
curl -X POST http://localhost:8085/api/v1/monitoring/metrics \
  -H "X-Tenant-ID: tenant-a" \
  -H "Content-Type: application/json" \
  -d '{"name": "cpu_usage", "value": 80.0}'
```

Tenant B:
```bash
curl -X POST http://localhost:8085/api/v1/monitoring/metrics \
  -H "X-Tenant-ID: tenant-b" \
  -H "Content-Type: application/json" \
  -d '{"name": "cpu_usage", "value": 45.0}'
```

Each tenant sees only their own metrics.

## Data Model

### Metric Types

1. **Gauge**: Instantaneous measurement (e.g., CPU usage, memory usage)
2. **Counter**: Cumulative value that increases (e.g., request count)
3. **Histogram**: Distribution of values (e.g., response times)

### Alert Severity Levels

- **info**: Informational alerts
- **warning**: Warning alerts requiring attention
- **critical**: Critical alerts requiring immediate action

### Health Check Statuses

- **healthy**: Service operating normally
- **degraded**: Service operational but experiencing issues
- **unhealthy**: Service not operational

## Configuration

### Port Configuration
Default port: **8085**

Configured in [app.d](source/app.d):
```d
auto settings = new HTTPServerSettings;
settings.port = 8085;
settings.bindAddresses = ["0.0.0.0"];
```

### Data Retention
- **Metrics**: Last 10,000 metrics retained (rolling window)
- **Alerts**: All alerts retained (active and resolved)
- **Health Checks**: Latest check per service retained

## Building and Running

### Build with DUB
```bash
cd monitoring
dub build
```

### Run the Service
```bash
./uim-iaas-monitoring
```

### Run with Docker
```bash
docker build -t uim-iaas-monitoring .
docker run -p 8085:8085 uim-iaas-monitoring
```

### Run with Docker Compose
From the project root:
```bash
docker-compose up monitoring
```

## Dependencies

Defined in [dub.sdl](dub.sdl):

- **vibe-d**: Web framework and HTTP server
- **uim-iaas-core**: Core entities and utilities

## Integration with Other Services

### Service Registration
Other services should register themselves and report metrics:

```d
// Compute Service example
auto client = new HTTPClient();
client.post("http://monitoring:8085/api/v1/monitoring/metrics", Json({
    "name": "vm_created",
    "type": "counter",
    "value": 1,
    "labels": {
        "service": "compute"
    }
}), ["X-Tenant-ID": tenantId]);
```

### Health Check Reporting
Services should periodically report health:

```d
// Every 30 seconds
setTimer(30.seconds, true, {
    client.post("http://monitoring:8085/api/v1/monitoring/health-checks", Json({
        "service": "compute-service",
        "status": "healthy",
        "responseTime": responseTime
    }), ["X-Tenant-ID": tenantId]);
});
```

## Observability Best Practices

### Metric Naming Convention
Use hierarchical naming with underscores:
- `service_request_count`
- `vm_cpu_usage_percent`
- `storage_disk_bytes_free`

### Label Usage
Use labels for dimensional data:
```json
{
  "name": "request_duration_ms",
  "value": 150,
  "labels": {
    "method": "POST",
    "endpoint": "/api/v1/vms",
    "status": "200"
  }
}
```

### Alert Design
- Set clear severity levels
- Include actionable messages
- Reference the source service
- Resolve alerts when conditions clear

## Monitoring the Monitor

The monitoring service itself exposes health status:
```bash
curl http://localhost:8085/health
```

Response:
```json
{
  "status": "healthy",
  "service": "monitoring-service"
}
```

## Performance Considerations

- **In-Memory Storage**: Fast but limited to 10,000 metrics
- **No Persistence**: Data lost on restart (suitable for development)
- **Future Enhancement**: Add persistent storage (database/time-series DB)

## Future Enhancements

1. **Persistent Storage**: PostgreSQL/TimescaleDB integration
2. **Metric Retention Policies**: Configurable retention periods
3. **Alerting Rules Engine**: Automated alert triggering based on thresholds
4. **Webhook Notifications**: Alert delivery to external systems
5. **Grafana Integration**: Export metrics in Prometheus format
6. **Query Language**: Advanced metric querying (PromQL-like)
7. **Metric Downsampling**: Automatic aggregation for older data

## Troubleshooting

### Service Not Starting
Check port availability:
```bash
netstat -tuln | grep 8085
```

### No Metrics Visible
Verify tenant ID is set:
```bash
curl -H "X-Tenant-ID: your-tenant" http://localhost:8085/api/v1/monitoring/metrics
```

### High Memory Usage
Metrics buffer may be full. Restart service to clear:
```bash
docker-compose restart monitoring
```

## Testing

### Manual Testing
Use the provided test script:
```bash
bash ../scripts/test-multitenancy.sh
```

### API Testing with cURL
```bash
# Record a test metric
curl -X POST http://localhost:8085/api/v1/monitoring/metrics \
  -H "X-Tenant-ID: test-tenant" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test_metric",
    "type": "gauge",
    "value": 42.0,
    "labels": {"env": "test"}
  }'

# Retrieve metrics
curl -H "X-Tenant-ID: test-tenant" \
  http://localhost:8085/api/v1/monitoring/metrics
```

## License

See [LICENSE](LICENSE) file for details.

## Related Documentation

- [Project Architecture](../docs/ARCHITECTURE.md)
- [Multi-Tenancy Guide](../docs/MULTI_TENANCY.md)
- [API Examples](../docs/API_EXAMPLES.md)
- [Quick Start Guide](../docs/QUICKSTART.md)

## Contact

For issues and contributions, please refer to the main project repository.

---

**Monitoring Service Version**: 1.0.0  
**NAF Version**: v4  
**Last Updated**: January 2026
