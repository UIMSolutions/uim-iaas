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
skinparam classAttributeIconSize 0
skinparam shadowing false

package "uim.iaas.core" {
    abstract class IaasEntity {
        #string _id
        #long _createdAt
        #long _updatedAt
        #string[string] _metadata
        __
        +id() : string
        +id(string) : void
        +createdAt() : long
        +createdAt(long) : void
        +updatedAt() : long
        +updatedAt(long) : void
        +metadata() : string[string]
        +metadata(string, string) : void
        +toJson() : Json
    }
}

package "uim.iaas.monitoring.entities" {
    class MetricEntity {
        -string _name
        -string _tenantId
        -string _type
        -double _value
        -string[string] _labels
        -long _timestamp
        __
        +name() : string
        +name(string) : void
        +tenantId() : string
        +tenantId(string) : void
        +type() : string
        +type(string) : void
        +value() : double
        +value(double) : void
        +labels() : string[string]
        +labels(string[string]) : void
        +labels(string) : string
        +labels(string, string) : void
        +timestamp() : long
        +timestamp(long) : void
        +toJson() : Json
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
        __
        +name() : string
        +name(string) : void
        +tenantId() : string
        +tenantId(string) : void
        +severity() : string
        +severity(string) : void
        +message() : string
        +message(string) : void
        +source() : string
        +source(string) : void
        +active() : bool
        +active(bool) : void
        +triggeredAt() : long
        +triggeredAt(long) : void
        +resolvedAt() : long
        +resolvedAt(long) : void
        +toJson() : Json
    }
    
    class HealthCheckEntity {
        -string _service
        -string _tenantId
        -string _status
        -long _responseTime
        -string _message
        -long _timestamp
        __
        +service() : string
        +service(string) : void
        +tenantId() : string
        +tenantId(string) : void
        +status() : string
        +status(string) : void
        +responseTime() : long
        +responseTime(long) : void
        +message() : string
        +message(string) : void
        +timestamp() : long
        +timestamp(long) : void
        +toJson() : Json
    }
    
    IaasEntity <|-- MetricEntity
    IaasEntity <|-- AlertEntity
    IaasEntity <|-- HealthCheckEntity
    
    note right of MetricEntity
        Metric Types:
        - gauge: instantaneous value
        - counter: cumulative value
        - histogram: distribution
    end note
    
    note right of AlertEntity
        Severity Levels:
        - info
        - warning
        - critical
    end note
    
    note right of HealthCheckEntity
        Status Values:
        - healthy
        - degraded
        - unhealthy
    end note
}

package "uim.iaas.monitoring.services" {
    class MonitoringService {
        -MetricEntity[] metrics
        -AlertEntity[string] alerts
        -HealthCheckEntity[string] healthChecks
        __
        .. Route Setup ..
        +setupRoutes(URLRouter) : void
        .. Health Endpoint ..
        +healthCheck(req, res) : void
        .. Metrics Operations ..
        +getMetrics(req, res) : void
        +recordMetric(req, res) : void
        +getMetricsByName(req, res) : void
        .. Alerts Operations ..
        +listAlerts(req, res) : void
        +getAlert(req, res) : void
        +createAlert(req, res) : void
        +resolveAlert(req, res) : void
        .. Health Check Operations ..
        +listHealthChecks(req, res) : void
        +recordHealthCheck(req, res) : void
        .. Dashboard ..
        +getDashboard(req, res) : void
        .. Helper Methods ..
        -getTenantIdFromRequest(req) : string
    }
    
    MonitoringService "1" *-- "0..*" MetricEntity : manages >
    MonitoringService "1" *-- "0..*" AlertEntity : manages >
    MonitoringService "1" *-- "0..*" HealthCheckEntity : manages >
    
    note bottom of MonitoringService
        - Stores max 10,000 metrics (rolling)
        - All operations are tenant-isolated
        - In-memory storage (no persistence)
    end note
}

@enduml
```

### Sequence Diagram: Recording a Metric

```plantuml
@startuml
!theme plain
autonumber

actor "Client/Service" as Client
participant "API Gateway" as Gateway
participant "MonitoringService" as Service
participant "MetricEntity" as Entity
database "metrics[]" as Store

Client -> Gateway: POST /api/v1/monitoring/metrics\n{name, type, value, labels}
activate Gateway

Gateway -> Gateway: Validate authentication
Gateway -> Gateway: Extract X-Tenant-ID

Gateway -> Service: recordMetric(req, res)
activate Service

Service -> Service: getTenantIdFromRequest(req)
note right: Extract tenant from\nX-Tenant-ID header

Service -> Service: Parse JSON body
note right
    Required fields:
    - name
    - value
    Optional:
    - type (default: "gauge")
    - labels {}
end note

Service -> Entity: new MetricEntity()
activate Entity
Entity --> Service: entity instance
deactivate Entity

Service -> Entity: set name
Service -> Entity: set tenantId
Service -> Entity: set type
Service -> Entity: set value
Service -> Entity: set timestamp = now()

alt labels provided
    loop for each label
        Service -> Entity: labels(key, value)
    end
end

Service -> Entity: toJson()
activate Entity
Entity --> Service: metric JSON
deactivate Entity

Service -> Store: metrics ~= metric
activate Store
note right: Append to array

alt metrics.length > 10000
    Store -> Store: Keep last 10,000 only
    note right: Rolling window\nto prevent memory overflow
end

Store --> Service: stored
deactivate Store

Service --> Gateway: 201 Created\n{metric JSON}
deactivate Service

Gateway --> Client: 201 Created\n{id, name, value, ...}
deactivate Gateway

@enduml
```

### Sequence Diagram: Dashboard Retrieval

```plantuml
@startuml
!theme plain
autonumber

actor User
participant "Web Client" as Client
participant "MonitoringService" as Service
database "alerts{}" as AlertStore
database "healthChecks{}" as HealthStore
database "metrics[]" as MetricStore

User -> Client: Request Dashboard
Client -> Service: GET /api/v1/monitoring/dashboard\nX-Tenant-ID: tenant-123
activate Service

Service -> Service: getTenantIdFromRequest(req)
note right: tenantId = "tenant-123"

group Alert Statistics
    Service -> AlertStore: Query active alerts for tenant
    activate AlertStore
    AlertStore --> Service: alerts[]
    deactivate AlertStore
    
    Service -> Service: Initialize counters:\ncritical=0, warning=0, info=0
    
    loop for each alert
        alt alert.tenantId == tenantId && alert.active
            Service -> Service: Increment counter by severity
            note right
                switch(alert.severity):
                  case "critical": criticalCount++
                  case "warning": warningCount++
                  case "info": infoCount++
            end note
        end
    end
    
    Service -> Service: totalAlerts = critical + warning + info
end

group Service Health Statistics
    Service -> HealthStore: Query health checks for tenant
    activate HealthStore
    HealthStore --> Service: healthChecks[]
    deactivate HealthStore
    
    Service -> Service: Initialize counters:\nhealthy=0, degraded=0, unhealthy=0
    
    loop for each health check
        alt healthCheck.tenantId == tenantId
            Service -> Service: Increment counter by status
            note right
                switch(healthCheck.status):
                  case "healthy": healthyCount++
                  case "degraded": degradedCount++
                  case "unhealthy": unhealthyCount++
            end note
        end
    end
    
    Service -> Service: totalServices = healthy + degraded + unhealthy
end

group Metrics Statistics
    Service -> Service: recentTime = now() - 3600
    note right: Last hour timestamp
    
    Service -> MetricStore: Query all metrics
    activate MetricStore
    MetricStore --> Service: metrics[]
    deactivate MetricStore
    
    Service -> Service: totalCount = 0\nrecentCount = 0
    
    loop for each metric
        alt metric.tenantId == tenantId
            Service -> Service: totalCount++
            alt metric.timestamp >= recentTime
                Service -> Service: recentCount++
            end
        end
    end
end

Service -> Service: Build dashboard JSON:\n- timestamp: now()\n- alerts: {...}\n- services: {...}\n- metrics: {...}

Service --> Client: 200 OK\n{dashboard: {...}}
deactivate Service

Client -> Client: Parse and format data

Client --> User: Display Dashboard:\n- Alert counts by severity\n- Service health summary\n- Metric statistics

@enduml
```

### State Diagram: Alert Lifecycle

```plantuml
@startuml
!theme plain

[*] --> Active : createAlert()

state Active {
    Active : active = true
    Active : triggeredAt = timestamp
    Active : resolvedAt = 0
    Active : severity = (critical|warning|info)
    --
    Active : Alert is visible in active alerts list
    Active : Counted in dashboard statistics
    Active : Can be queried by ID
}

Active --> Resolved : resolveAlert(id)

state Resolved {
    Resolved : active = false
    Resolved : resolvedAt = timestamp
    --
    Resolved : No longer in active alerts list
    Resolved : Still accessible by ID
    Resolved : Available in alert history
}

Resolved --> [*]

note right of Active
    Actions while Active:
    - GET /alerts (with active=true filter)
    - GET /alerts/:id
    - POST /alerts/:id/resolve
end note

note right of Resolved
    Resolved alerts remain in memory
    but are excluded from active
    alert queries and dashboard counts
end note

@enduml
```

### Use Case Diagram

```plantuml
@startuml
!theme plain
left to right direction

actor "Tenant User" as User
actor "Microservice" as Service
actor "Web Dashboard" as Dashboard
actor "Administrator" as Admin

rectangle "Monitoring Service API" {
    
    package "Metrics Management" {
        usecase "Record Metric" as UC1
        usecase "Query Metrics" as UC2
        usecase "Get Metrics by Name" as UC3
        usecase "Calculate Aggregations" as UC4
    }
    
    package "Alert Management" {
        usecase "Create Alert" as UC5
        usecase "List Alerts" as UC6
        usecase "Get Alert Details" as UC7
        usecase "Resolve Alert" as UC8
        usecase "Filter Active Alerts" as UC9
    }
    
    package "Health Monitoring" {
        usecase "Record Health Check" as UC10
        usecase "List Health Checks" as UC11
        usecase "Query Service Status" as UC12
    }
    
    package "Dashboard" {
        usecase "Get Dashboard" as UC13
        usecase "View Alert Summary" as UC14
        usecase "View Service Health" as UC15
        usecase "View Metrics Stats" as UC16
    }
    
    package "System" {
        usecase "Health Check" as UC17
        usecase "Tenant Isolation" as UC18
        usecase "Data Retention" as UC19
    }
}

' Metrics relationships
Service --> UC1
Service --> UC2
User --> UC2
User --> UC3
UC3 ..> UC4 : <<include>>

' Alert relationships
Service --> UC5
User --> UC6
User --> UC7
User --> UC8
UC6 ..> UC9 : <<extend>>

' Health Check relationships
Service --> UC10
User --> UC11
Dashboard --> UC11
UC11 ..> UC12 : <<include>>

' Dashboard relationships
Dashboard --> UC13
User --> UC13
UC13 ..> UC14 : <<include>>
UC13 ..> UC15 : <<include>>
UC13 ..> UC16 : <<include>>

' System relationships
Admin --> UC17
UC1 ..> UC18 : <<include>>
UC2 ..> UC18 : <<include>>
UC5 ..> UC18 : <<include>>
UC10 ..> UC18 : <<include>>
UC1 ..> UC19 : <<include>>

note right of UC1
    Services continuously record
    metrics for monitoring
end note

note right of UC5
    Alerts can be created
    manually or automatically
end note

note right of UC10
    Services report their
    health status periodically
end note

note bottom of UC18
    All operations are
    tenant-scoped via
    X-Tenant-ID header
end note

note bottom of UC19
    Max 10,000 metrics stored
    Alerts: all retained
    Health: latest per service
end note

@enduml
```

### Component Diagram

```plantuml
@startuml
!theme plain

package "Monitoring Service Container" {
    component [app.d\nMain Entry Point] as App
    
    package "Service Layer" {
        component [MonitoringService] as Service
        note right of Service
            Routes:
            - /health
            - /api/v1/monitoring/metrics
            - /api/v1/monitoring/alerts
            - /api/v1/monitoring/health-checks
            - /api/v1/monitoring/dashboard
        end note
    }
    
    package "Entity Models" {
        component [MetricEntity] as Metric
        component [AlertEntity] as Alert
        component [HealthCheckEntity] as Health
    }
    
    package "Data Stores" {
        database "metrics[]\n(max 10k)" as MetricStore
        database "alerts{}\n(by ID)" as AlertStore
        database "healthChecks{}\n(by service)" as HealthStore
    }
    
    App --> Service : initializes
    Service --> Metric : creates/uses
    Service --> Alert : creates/uses
    Service --> Health : creates/uses
    Service --> MetricStore : read/write
    Service --> AlertStore : read/write
    Service --> HealthStore : read/write
}

' External Dependencies
component [vibe.d HTTP Server\nPort: 8085] as Vibe
component [uim.iaas.core\nIaasEntity] as Core
component [API Gateway\nPort: 8080] as Gateway

App ..> Vibe : uses
Service ..> Vibe : URLRouter
Metric --|> Core : extends
Alert --|> Core : extends
Health --|> Core : extends

' External Services
cloud "IaaS Microservices" {
    component [Compute Service\n:8081] as Compute
    component [Storage Service\n:8082] as Storage
    component [Network Service\n:8083] as Network
    component [Auth Service\n:8084] as Auth
}

cloud "Client Applications" {
    component [Web Dashboard] as WebUI
    component [CLI Tools] as CLI
    component [External Monitors] as External
}

' Interactions
Gateway --> App : HTTP/REST\n+ X-Tenant-ID
Compute --> Gateway : POST metrics\nPOST health-checks
Storage --> Gateway : POST metrics\nPOST health-checks
Network --> Gateway : POST metrics\nPOST health-checks
Auth --> Gateway : POST metrics\nPOST health-checks

WebUI --> Gateway : GET dashboard\nGET metrics\nGET alerts
CLI --> Gateway : All operations
External --> Gateway : GET metrics\nGET health

note right of Gateway
    Gateway adds tenant context
    via X-Tenant-ID header
end note

note bottom of MetricStore
    In-Memory Storage:
    - Fast access
    - No persistence
    - Rolling window
end note

@enduml
```

### Activity Diagram: Query Metrics with Aggregations

```plantuml
@startuml
!theme plain

start

:Receive GET /metrics/:name request;

:Extract tenant ID from X-Tenant-ID header;

:Extract metric name from URL parameter;

:Initialize: filtered = [];

:Query all metrics from storage;

partition "Filter Metrics" {
    :Start iteration over all metrics;
    
    repeat
        :Get next metric;
        
        if (metric.name == requested name?) then (yes)
            if (metric.tenantId == tenant?) then (yes)
                :Add metric to filtered list;
            else (no)
                :Skip metric (different tenant);
            endif
        else (no)
            :Skip metric (different name);
        endif
        
    repeat while (more metrics?) is (yes)
    ->no;
}

if (filtered list empty?) then (yes)
    :Build response with count=0;
    :Return 200 OK with empty result;
    stop
else (no)
    partition "Calculate Aggregations" {
        :Initialize:\nsum = 0\nmin = MAX_VALUE\nmax = MIN_VALUE;
        
        :Start aggregation loop;
        
        repeat
            :Get next filtered metric;
            :sum += metric.value;
            
            if (metric.value < min?) then (yes)
                :min = metric.value;
            endif
            
            if (metric.value > max?) then (yes)
                :max = metric.value;
            endif
            
        repeat while (more filtered metrics?) is (yes)
        ->no;
        
        :avg = sum / count;
    }
    
    :Build JSON array of metrics;
    
    :Build aggregations object:\n- min\n- max\n- avg\n- sum;
    
    :Build response:\n- name\n- metrics[]\n- count\n- aggregations{};
    
    :Return 200 OK with full result;
    
    stop
endif

@enduml
```

### Activity Diagram: Dashboard Generation

```plantuml
@startuml
!theme plain

start

:Receive GET /dashboard request;

:Extract tenant ID from X-Tenant-ID header;

:timestamp = getCurrentTime();

fork
    partition "Process Alerts" {
        :Initialize counters:\ncritical=0, warning=0, info=0;
        
        :Query all alerts;
        
        repeat
            :Get next alert;
            
            if (alert.tenantId == tenant?) then (yes)
                if (alert.active == true?) then (yes)
                    switch (alert.severity?)
                    case ( critical )
                        :critical++;
                    case ( warning )
                        :warning++;
                    case ( info )
                        :info++;
                    endswitch
                endif
            endif
            
        repeat while (more alerts?) is (yes)
        ->no;
        
        :alertTotal = critical + warning + info;
        
        :Store alert statistics;
    }
    
fork again
    partition "Process Health Checks" {
        :Initialize counters:\nhealthy=0, degraded=0, unhealthy=0;
        
        :Query all health checks;
        
        repeat
            :Get next health check;
            
            if (healthCheck.tenantId == tenant?) then (yes)
                switch (healthCheck.status?)
                case ( healthy )
                    :healthy++;
                case ( degraded )
                    :degraded++;
                case ( unhealthy )
                    :unhealthy++;
                endswitch
            endif
            
        repeat while (more health checks?) is (yes)
        ->no;
        
        :serviceTotal = healthy + degraded + unhealthy;
        
        :Store health statistics;
    }
    
fork again
    partition "Process Metrics" {
        :recentTime = timestamp - 3600;\nnote: Last hour;
        
        :Initialize counters:\ntotal=0, lastHour=0;
        
        :Query all metrics;
        
        repeat
            :Get next metric;
            
            if (metric.tenantId == tenant?) then (yes)
                :total++;
                
                if (metric.timestamp >= recentTime?) then (yes)
                    :lastHour++;
                endif
            endif
            
        repeat while (more metrics?) is (yes)
        ->no;
        
        :Store metric statistics;
    }
    
end fork

:Assemble dashboard JSON:\n- timestamp\n- alerts{critical, warning, info, total}\n- services{healthy, degraded, unhealthy, total}\n- metrics{total, lastHour};

:Return 200 OK with dashboard data;

stop

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

## Key Features

### Metrics Collection
- **Time-Series Data**: Store metrics with timestamps for historical analysis
- **Labels Support**: Add dimensional metadata to metrics (host, region, environment)
- **Metric Types**: Support for gauge, counter, and histogram metrics
- **Aggregations**: Automatic min, max, avg, sum calculations
- **Filtering**: Query metrics by name and time range

### Alert Management
- **Severity Levels**: info, warning, critical
- **Alert States**: Active and resolved states
- **Source Tracking**: Identify which service triggered the alert
- **Alert Resolution**: Mark alerts as resolved with timestamps
- **Alert Filtering**: Query active alerts or all alerts

### Health Monitoring
- **Service Status**: Track healthy, degraded, and unhealthy states
- **Response Time**: Measure service response times
- **Per-Service Tracking**: Monitor each microservice independently
- **Latest Status**: Always shows the most recent health check per service

### Dashboard
- **Unified View**: Single endpoint for all monitoring data
- **Alert Summary**: Count of critical, warning, and info alerts
- **Service Health**: Overview of all service statuses
- **Metric Statistics**: Total metrics and recent activity
- **Real-Time**: Dashboard data updated in real-time

## Configuration

### Port Configuration
Default port: **8085**

Configured in [app.d](source/app.d):
```d
auto settings = new HTTPServerSettings;
settings.port = 8085;
settings.bindAddresses = ["0.0.0.0"];
```

### Service Settings
| Setting | Default | Description |
|---------|---------|-------------|
| Port | 8085 | HTTP server port |
| Bind Address | 0.0.0.0 | Network interface to bind |
| Max Metrics | 10,000 | Maximum metrics stored in memory |
| Tenant Header | X-Tenant-ID | HTTP header for tenant identification |

### Data Retention
- **Metrics**: Last 10,000 metrics retained (rolling window)
- **Alerts**: All alerts retained (active and resolved)
- **Health Checks**: Latest check per service retained

### Storage Model
- **In-Memory**: All data stored in RAM for fast access
- **Ephemeral**: Data cleared on service restart
- **Production Note**: For production use, implement persistent storage backend

## Building and Running

### Prerequisites
- D compiler (DMD, LDC, or GDC)
- DUB package manager
- vibe.d framework (automatically installed via DUB)

### Build with DUB
```bash
cd monitoring
dub build
```

For release build with optimizations:
```bash
dub build --build=release
```

### Run the Service
```bash
./uim-iaas-monitoring
```

Or directly with DUB:
```bash
dub run
```

The service will start and listen on port 8085:
```
Monitoring Service starting on port 8085
```

### Run with Docker
Build the Docker image:
```bash
docker build -t uim-iaas-monitoring:latest .
```

Run the container:
```bash
docker run -p 8085:8085 uim-iaas-monitoring:latest
```

With custom port:
```bash
docker run -p 9090:8085 \
  -e SERVICE_PORT=8085 \
  uim-iaas-monitoring:latest
```

### Run with Docker Compose
From the project root:
```bash
docker-compose up monitoring
```

Run in detached mode:
```bash
docker-compose up -d monitoring
```

View logs:
```bash
docker-compose logs -f monitoring
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

## Quick Start Guide

### 1. Clone and Build
```bash
# Clone the repository
git clone https://github.com/UIMSolutions/uim-iaas.git
cd uim-iaas/monitoring

# Build the service
dub build

# Run the service
dub run
```

### 2. Verify Service is Running
```bash
curl http://localhost:8085/health
```

### 3. Record Your First Metric
```bash
curl -X POST http://localhost:8085/api/v1/monitoring/metrics \
  -H "X-Tenant-ID: my-tenant" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test_metric",
    "type": "gauge",
    "value": 100,
    "labels": {
      "environment": "development"
    }
  }'
```

### 4. View Your Metrics
```bash
curl -H "X-Tenant-ID: my-tenant" \
  http://localhost:8085/api/v1/monitoring/metrics
```

### 5. Create an Alert
```bash
curl -X POST http://localhost:8085/api/v1/monitoring/alerts \
  -H "X-Tenant-ID: my-tenant" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Alert",
    "severity": "info",
    "message": "This is a test alert",
    "source": "test"
  }'
```

### 6. View Dashboard
```bash
curl -H "X-Tenant-ID: my-tenant" \
  http://localhost:8085/api/v1/monitoring/dashboard
```

## Troubleshooting

### Service Not Starting

**Problem**: Service fails to start or exits immediately

**Solutions**:

1. **Check Port Availability**
   ```bash
   netstat -tuln | grep 8085
   # or
   lsof -i :8085
   ```
   
   If port is in use, stop the conflicting process or change the port in `source/app.d`

2. **Check Dependencies**
   ```bash
   dub describe
   ```
   
   Ensure all dependencies are resolved

3. **View Detailed Logs**
   ```bash
   dub run --verbose
   ```

### No Metrics Visible

**Problem**: Metrics are recorded but not appearing in queries

**Solutions**:

1. **Verify Tenant ID**
   ```bash
   # Make sure you're using the same tenant ID for recording and querying
   curl -H "X-Tenant-ID: your-tenant" \
     http://localhost:8085/api/v1/monitoring/metrics
   ```

2. **Check Time Range**
   ```bash
   # Query without time filters first
   curl -H "X-Tenant-ID: your-tenant" \
     "http://localhost:8085/api/v1/monitoring/metrics"
   ```

3. **Verify Metric Was Recorded**
   Check the response status when recording:
   ```bash
   curl -v -X POST http://localhost:8085/api/v1/monitoring/metrics \
     -H "X-Tenant-ID: your-tenant" \
     -H "Content-Type: application/json" \
     -d '{"name": "test", "type": "gauge", "value": 1}'
   ```
   
   Should return `201 Created`

### High Memory Usage

**Problem**: Service consuming excessive memory

**Solutions**:

1. **Check Metric Count**
   The service stores up to 10,000 metrics in memory
   ```bash
   curl -H "X-Tenant-ID: your-tenant" \
     http://localhost:8085/api/v1/monitoring/dashboard
   ```

2. **Restart Service**
   ```bash
   # Docker
   docker-compose restart monitoring
   
   # Direct
   pkill uim-iaas-monitoring
   dub run
   ```

3. **Reduce Metric Ingestion Rate**
   Consider sampling metrics less frequently or implementing metric downsampling

### Alerts Not Appearing

**Problem**: Created alerts don't show in list

**Solutions**:

1. **Check Alert Status Filter**
   ```bash
   # List all alerts (not just active)
   curl -H "X-Tenant-ID: your-tenant" \
     "http://localhost:8085/api/v1/monitoring/alerts"
   ```

2. **Verify Tenant ID Matches**
   Alerts are tenant-scoped

3. **Check Alert Creation Response**
   Ensure alert was created successfully (201 Created)

### Connection Refused

**Problem**: Cannot connect to monitoring service

**Solutions**:

1. **Verify Service is Running**
   ```bash
   ps aux | grep uim-iaas-monitoring
   # or
   docker ps | grep monitoring
   ```

2. **Check Firewall Rules**
   ```bash
   sudo ufw status
   # or
   sudo iptables -L -n
   ```

3. **Verify Network Configuration**
   ```bash
   # Check if service is listening
   netstat -tuln | grep 8085
   ```

### JSON Parse Errors

**Problem**: Service returns 400 Bad Request with JSON errors

**Solutions**:

1. **Validate JSON**
   ```bash
   # Use jq to validate JSON
   echo '{"name": "test", "value": 100}' | jq .
   ```

2. **Check Content-Type Header**
   ```bash
   curl -X POST http://localhost:8085/api/v1/monitoring/metrics \
     -H "Content-Type: application/json" \  # Required!
     -H "X-Tenant-ID: tenant" \
     -d '{"name": "test", "type": "gauge", "value": 100}'
   ```

3. **Verify Required Fields**
   - Metrics: `name`, `value` required
   - Alerts: `name`, `message` required
   - Health Checks: `service`, `status` required

### Service Performance Issues

**Problem**: Slow response times or high latency

**Solutions**:

1. **Check Metric Count**
   Large metric collections can slow queries
   ```bash
   curl -H "X-Tenant-ID: your-tenant" \
     http://localhost:8085/api/v1/monitoring/dashboard
   ```

2. **Use Time Range Filters**
   ```bash
   # Query specific time range instead of all metrics
   START=$(date -d '1 hour ago' +%s)
   END=$(date +%s)
   curl -H "X-Tenant-ID: your-tenant" \
     "http://localhost:8085/api/v1/monitoring/metrics?start=$START&end=$END"
   ```

3. **Monitor System Resources**
   ```bash
   # CPU and memory usage
   top -p $(pgrep uim-iaas-monitoring)
   ```

### Docker Issues

**Problem**: Container won't start or keeps restarting

**Solutions**:

1. **Check Container Logs**
   ```bash
   docker-compose logs monitoring
   # or
   docker logs <container-id>
   ```

2. **Verify Docker Image**
   ```bash
   docker images | grep uim-iaas-monitoring
   ```

3. **Rebuild Image**
   ```bash
   docker-compose build --no-cache monitoring
   docker-compose up monitoring
   ```

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

### Manual Testing with cURL

#### 1. Health Check
```bash
curl http://localhost:8085/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "monitoring-service"
}
```

#### 2. Record a Metric
```bash
curl -X POST http://localhost:8085/api/v1/monitoring/metrics \
  -H "X-Tenant-ID: test-tenant" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "cpu_usage",
    "type": "gauge",
    "value": 75.5,
    "labels": {
      "host": "server-01",
      "region": "us-east"
    }
  }'
```

#### 3. Retrieve All Metrics
```bash
curl -H "X-Tenant-ID: test-tenant" \
  http://localhost:8085/api/v1/monitoring/metrics
```

#### 4. Get Metrics by Name with Aggregations
```bash
curl -H "X-Tenant-ID: test-tenant" \
  http://localhost:8085/api/v1/monitoring/metrics/cpu_usage
```

#### 5. Create an Alert
```bash
curl -X POST http://localhost:8085/api/v1/monitoring/alerts \
  -H "X-Tenant-ID: test-tenant" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "High CPU Alert",
    "severity": "critical",
    "message": "CPU usage exceeded 90%",
    "source": "compute-service"
  }'
```

#### 6. List Active Alerts
```bash
curl -H "X-Tenant-ID: test-tenant" \
  "http://localhost:8085/api/v1/monitoring/alerts?active=true"
```

#### 7. Record Health Check
```bash
curl -X POST http://localhost:8085/api/v1/monitoring/health-checks \
  -H "X-Tenant-ID: test-tenant" \
  -H "Content-Type: application/json" \
  -d '{
    "service": "compute-service",
    "status": "healthy",
    "responseTime": 120,
    "message": "All systems operational"
  }'
```

#### 8. Get Dashboard
```bash
curl -H "X-Tenant-ID: test-tenant" \
  http://localhost:8085/api/v1/monitoring/dashboard
```

### Automated Testing

#### Run DUB Tests
```bash
dub test
```

#### Multi-Tenancy Testing
Use the provided test script:
```bash
bash ../scripts/test-multitenancy.sh
```

### Performance Testing

Test metric ingestion rate:
```bash
# Record 100 metrics
for i in {1..100}; do
  curl -X POST http://localhost:8085/api/v1/monitoring/metrics \
    -H "X-Tenant-ID: perf-test" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"test_metric_$i\", \"type\": \"gauge\", \"value\": $i}" &
done
wait
```

### Integration Testing

Test with other services:
```bash
# Start all services
docker-compose up -d

# Test monitoring from compute service
curl -X POST http://localhost:8085/api/v1/monitoring/metrics \
  -H "X-Tenant-ID: integration-test" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "vm_created",
    "type": "counter",
    "value": 1,
    "labels": {
      "service": "compute",
      "operation": "create"
    }
  }'

# Verify metric was recorded
curl -H "X-Tenant-ID: integration-test" \
  http://localhost:8085/api/v1/monitoring/metrics/vm_created
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Address already in use` | Port 8085 is occupied | Change port or stop conflicting service |
| `Failed to load package` | Missing dependencies | Run `dub fetch` and `dub build` |
| `Tenant not found` | Missing X-Tenant-ID header | Add header to request |
| `404 Not Found` | Invalid endpoint | Check API documentation for correct path |
| `500 Internal Server Error` | Server-side issue | Check logs with `dub run --verbose` |

### Getting Help

If you continue to experience issues:

1. Check the [project issues](https://github.com/UIMSolutions/uim-iaas/issues)
2. Review the [project documentation](../docs/)
3. Enable verbose logging: `dub run --verbose`
4. Collect diagnostic information:
   ```bash
   curl http://localhost:8085/health
   dub --version
   dmd --version
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
