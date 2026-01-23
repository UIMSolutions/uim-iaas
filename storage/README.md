# UIM IaaS Storage Service

## Overview

The **UIM IaaS Storage Service** is a comprehensive multi-tenant storage management platform that provides both block storage (volumes) and object storage (buckets) capabilities for cloud infrastructure. Built with the D programming language and vibe.d framework, it enables creation, attachment, and management of persistent storage resources with complete tenant isolation.

**Service Name:** `uim-iaas-storage`  
**Default Port:** 8082  
**NAF Version:** v4  
**Version:** 26.1.2 compatible

## Features

- ✅ Block storage volume management (create, attach, detach, delete)
- ✅ Object storage bucket management
- ✅ Volume snapshots for backup and recovery
- ✅ Multi-tenant storage isolation and security
- ✅ Volume attachment to compute instances
- ✅ Storage status tracking (available, in-use, creating, deleting)
- ✅ Regional bucket placement
- ✅ Size-based storage management (GB for volumes, bytes for objects)
- ✅ RESTful API with JSON responses
- ✅ Health check endpoint for monitoring
- ✅ Async volume creation with status updates
- ✅ NAF v4 architecture alignment

## NAF v4 Architecture Alignment

This service adheres to the **NATO Architecture Framework (NAF) Version 4** standards, ensuring structured architecture documentation and operational clarity.

### NAF v4 Views Implemented

#### NOV-1: High-Level Operational Concept
The Storage Service operates as the persistent data layer that:
- Provisions block storage volumes for compute instances
- Manages object storage buckets for unstructured data
- Handles volume lifecycle (create, attach, detach, snapshot, delete)
- Provides storage capacity management and tracking
- Ensures data persistence and availability across infrastructure
- Implements tenant-level storage isolation

#### NOV-2: Operational Node Connectivity
```
┌────────────────────────────────────────────────────┐
│               Storage Service Core                 │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────┐ │
│  │    Block     │  │    Object    │  │Snapshot │ │
│  │   Storage    │  │   Storage    │  │ Manager │ │
│  │  (Volumes)   │  │  (Buckets)   │  │         │ │
│  └──────┬───────┘  └──────┬───────┘  └────┬────┘ │
└─────────┼──────────────────┼───────────────┼──────┘
          │                  │               │
    ┌─────▼──────┐    ┌─────▼──────┐  ┌────▼─────┐
    │  Compute   │    │Application │  │ Backup   │
    │  Instances │    │  Services  │  │ Service  │
    └────────────┘    └────────────┘  └──────────┘
```

#### NOV-3: Operational Information Requirements
**Information Exchanged:**
- Volume specifications (size, type, status)
- Attachment relationships (volume ↔ instance)
- Bucket configurations and regions
- Storage capacity and utilization metrics
- Snapshot metadata and creation status
- Tenant isolation identifiers

#### NSV-1: Systems Interface Description
The Storage Service exposes RESTful HTTP interfaces for:
- Block volume lifecycle management (CRUD)
- Volume attachment/detachment operations
- Snapshot creation and management
- Object storage bucket provisioning
- Multi-tenant storage isolation

#### NSV-2: Systems Resource Flow
```
┌──────────────┐
│   Client     │
└──────┬───────┘
       │ POST /volumes (name, sizeGB: 100)
       ▼
┌──────────────────┐
│ Storage Service  │ Creates VolumeEntity (status: creating)
└──────┬───────────┘
       │ Async creation → status: available
       │ POST /volumes/:id/attach (instanceId)
       ▼
┌──────────────────┐
│Volume Attached   │ status: in-use, attachedTo: instance-id
└──────┬───────────┘
       │ Compute uses volume for data
       │ POST /volumes/:id/snapshot
       ▼
┌──────────────────┐
│ Snapshot Created │ Backup for recovery
└──────────────────┘
```

#### NSV-4: Systems Functionality Description

**Core Functions:**
1. **Block Volume Management**: Create, delete, query volumes with size specifications
2. **Volume Attachment**: Attach/detach volumes to/from compute instances
3. **Snapshot Management**: Create point-in-time backups of volumes
4. **Object Storage**: Bucket creation and management for unstructured data
5. **Multi-tenancy**: Complete storage isolation per tenant
6. **Status Tracking**: Monitor volume states (available, in-use, creating, deleting, error)
7. **Capacity Management**: Track storage size and utilization

## Architecture

### Entity-Service Pattern

The service implements a clean architecture with separation of concerns:

```
┌──────────────────────────────────────────────────────────┐
│                   Storage Service                         │
├──────────────────────────────────────────────────────────┤
│  Entities Layer                                          │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │ VolumeEntity │  │ BucketEntity │                     │
│  │              │  │              │                     │
│  │ - name       │  │ - name       │                     │
│  │ - tenantId   │  │ - tenantId   │                     │
│  │ - type       │  │ - region     │                     │
│  │ - sizeGB     │  │ - objectCount│                     │
│  │ - status     │  │ - sizeBytes  │                     │
│  │ - attachedTo │  │ - status     │                     │
│  └──────────────┘  └──────────────┘                     │
├──────────────────────────────────────────────────────────┤
│  Service Layer                                           │
│  ┌─────────────────────────────────────────────────────┐│
│  │            StorageService                           ││
│  │                                                     ││
│  │  Volume Operations:                                ││
│  │  + createVolume()    + listVolumes()               ││
│  │  + getVolume()       + deleteVolume()              ││
│  │  + attachVolume()    + detachVolume()              ││
│  │  + createSnapshot()                                ││
│  │                                                     ││
│  │  Bucket Operations:                                ││
│  │  + createBucket()    + listBuckets()               ││
│  │  + getBucket()       + deleteBucket()              ││
│  └─────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
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

package "uim.iaas.storage.entities" {
    class VolumeEntity {
        -string _name
        -string _tenantId
        -string _type
        -long _sizeGB
        -string _status
        -string _attachedTo
        __
        +name() : string
        +name(string) : void
        +tenantId() : string
        +tenantId(string) : void
        +type() : string
        +type(string) : void
        +sizeGB() : long
        +sizeGB(long) : void
        +status() : string
        +status(string) : void
        +attachedTo() : string
        +attachedTo(string) : void
        +toJson() : Json
    }
    
    class BucketEntity {
        -string _name
        -string _tenantId
        -string _region
        -long _objectCount
        -long _totalSizeBytes
        -string _status
        __
        +name() : string
        +name(string) : void
        +tenantId() : string
        +tenantId(string) : void
        +region() : string
        +region(string) : void
        +objectCount() : long
        +objectCount(long) : void
        +totalSizeBytes() : long
        +totalSizeBytes(long) : void
        +status() : string
        +status(string) : void
        +toJson() : Json
    }
    
    IaasEntity <|-- VolumeEntity
    IaasEntity <|-- BucketEntity
    
    note right of VolumeEntity
        Volume Types:
        - block: Block storage
        - object: Object storage
        
        Status Values:
        - available: Ready to attach
        - in-use: Attached to instance
        - creating: Being provisioned
        - deleting: Being removed
        - error: Creation/operation failed
    end note
    
    note right of BucketEntity
        Bucket for object storage
        
        Status Values:
        - active: Bucket operational
        - deleted: Bucket removed
        
        Tracks object count and
        total size in bytes
    end note
}

package "uim.iaas.storage.services" {
    class StorageService {
        -VolumeEntity[string] volumes
        -BucketEntity[string] buckets
        __
        .. Route Setup ..
        +setupRoutes(URLRouter) : void
        .. Health Endpoint ..
        +healthCheck(req, res) : void
        .. Volume Operations ..
        +listVolumes(req, res) : void
        +getVolume(req, res) : void
        +createVolume(req, res) : void
        +deleteVolume(req, res) : void
        +attachVolume(req, res) : void
        +detachVolume(req, res) : void
        +createSnapshot(req, res) : void
        .. Bucket Operations ..
        +listBuckets(req, res) : void
        +getBucket(req, res) : void
        +createBucket(req, res) : void
        +deleteBucket(req, res) : void
        .. Helper Methods ..
        -getTenantIdFromRequest(req) : string
    }
    
    StorageService "1" *-- "0..*" VolumeEntity : manages >
    StorageService "1" *-- "0..*" BucketEntity : manages >
    
    note bottom of StorageService
        - Async volume creation (1s delay)
        - Prevents deletion of attached volumes
        - Prevents deletion of non-empty buckets
        - All operations are tenant-isolated
    end note
}

@enduml
```

### Sequence Diagram: Creating and Attaching a Volume

```plantuml
@startuml
!theme plain
autonumber

actor "Compute Service" as Compute
participant "API Gateway" as Gateway
participant "StorageService" as Service
participant "VolumeEntity" as Entity
database "volumes{}" as Store
participant "Async Task" as Task

Compute -> Gateway: POST /api/v1/storage/volumes\n{name, sizeGB: 100}
activate Gateway

Gateway -> Gateway: Extract X-Tenant-ID
Gateway -> Service: createVolume(req, res)
activate Service

Service -> Service: getTenantIdFromRequest(req)
Service -> Service: Parse JSON body

Service -> Entity: new VolumeEntity()
activate Entity
Entity --> Service: entity instance
deactivate Entity

Service -> Entity: set id = UUID
Service -> Entity: set name
Service -> Entity: set tenantId
Service -> Entity: set type = "block"
Service -> Entity: set sizeGB = 100
Service -> Entity: set status = "creating"
Service -> Entity: set attachedTo = ""
Service -> Entity: set timestamps

Service -> Store: volumes[id] = volume
activate Store
Store --> Service: stored
deactivate Store

Service -> Task: runTask (async creation)
activate Task
note right: Simulates async\nprovisioning

Service -> Entity: toJson()
activate Entity
Entity --> Service: volume JSON
deactivate Entity

Service --> Gateway: 201 Created\n{id, status: "creating", ...}
deactivate Service

Gateway --> Compute: 201 Created\nvolumeId = "vol-123"
deactivate Gateway

Task -> Task: sleep(1 second)
Task -> Store: volumes[id].status = "available"
Task -> Store: volumes[id].updatedAt = now()
deactivate Task
note right: Volume now ready

...Wait for volume to be available...

Compute -> Gateway: POST /volumes/vol-123/attach\n{instanceId: "inst-456"}
activate Gateway

Gateway -> Service: attachVolume(req, res)
activate Service

Service -> Store: Check volume exists
activate Store
Store --> Service: volume found
deactivate Store

Service -> Service: Parse instanceId from body

Service -> Store: volumes[id].status = "in-use"
Service -> Store: volumes[id].attachedTo = "inst-456"
Service -> Store: volumes[id].updatedAt = now()

Service -> Entity: toJson()
activate Entity
Entity --> Service: volume JSON
deactivate Entity

Service --> Gateway: 200 OK\n{status: "in-use", attachedTo: "inst-456"}
deactivate Service

Gateway --> Compute: Volume attached successfully
deactivate Gateway

@enduml
```

### Sequence Diagram: Creating a Snapshot

```plantuml
@startuml
!theme plain
autonumber

actor User
participant "StorageService" as Service
database "volumes{}" as VolumeStore

User -> Service: POST /api/v1/storage/volumes/:id/snapshot\n{name: "backup-2026"}
activate Service

Service -> Service: Extract volume ID from URL

Service -> VolumeStore: Check volume exists
activate VolumeStore

alt volume not found
    VolumeStore --> Service: null
    deactivate VolumeStore
    Service --> User: 404 Not Found\n"Volume not found"
    
else volume exists
    VolumeStore --> Service: volume
    deactivate VolumeStore
    
    Service -> Service: Parse snapshot name from body
    
    Service -> Service: Generate snapshot ID (UUID)
    
    Service -> Service: Build snapshot JSON:\n- id\n- volumeId\n- name\n- status: "creating"\n- createdAt: timestamp
    
    note right of Service
        Snapshot represents a
        point-in-time copy of
        the volume for backup
    end note
    
    Service --> User: 201 Created\n{snapshot JSON}
end

deactivate Service

@enduml
```

### Sequence Diagram: Creating Object Storage Bucket

```plantuml
@startuml
!theme plain
autonumber

actor Application
participant "API Gateway" as Gateway
participant "StorageService" as Service
participant "BucketEntity" as Entity
database "buckets{}" as Store

Application -> Gateway: POST /api/v1/storage/buckets\n{name: "my-data", region: "us-east"}
activate Gateway

Gateway -> Service: createBucket(req, res)
activate Service

Service -> Service: getTenantIdFromRequest(req)
Service -> Service: Parse JSON body

Service -> Entity: new BucketEntity()
activate Entity
Entity --> Service: entity instance
deactivate Entity

Service -> Entity: set id = UUID
Service -> Entity: set name = "my-data"
Service -> Entity: set tenantId
Service -> Entity: set region = "us-east"
Service -> Entity: set objectCount = 0
Service -> Entity: set totalSizeBytes = 0
Service -> Entity: set status = "active"
Service -> Entity: set createdAt

alt metadata provided
    loop for each metadata entry
        Service -> Entity: metadata(key, value)
    end
end

Service -> Store: buckets[id] = bucket
activate Store
Store --> Service: stored
deactivate Store

Service -> Entity: toJson()
activate Entity
Entity --> Service: bucket JSON
deactivate Entity

Service --> Gateway: 201 Created\n{bucket details}
deactivate Service

Gateway --> Application: 201 Created\nbucketId = "bkt-789"
deactivate Gateway

@enduml
```

### State Diagram: Volume Lifecycle

```plantuml
@startuml
!theme plain

[*] --> Creating : createVolume()

state Creating {
    Creating : status = "creating"
    Creating : attachedTo = ""
    --
    Creating : Async provisioning in progress
    Creating : Cannot be attached or deleted
}

Creating --> Available : async task completes\n(after 1 second)
Creating --> Error : provisioning fails

state Available {
    Available : status = "available"
    Available : attachedTo = ""
    --
    Available : Ready to be attached
    Available : Can create snapshots
    Available : Can be deleted
}

Available --> InUse : attachVolume(instanceId)
Available --> Deleting : deleteVolume()

state InUse {
    InUse : status = "in-use"
    InUse : attachedTo = instanceId
    --
    InUse : Attached to compute instance
    InUse : Cannot be deleted
    InUse : Can create snapshots
}

InUse --> Available : detachVolume()

state Deleting {
    Deleting : Volume being removed
}

Deleting --> [*]

state Error {
    Error : status = "error"
    Error : Operation failed
    --
    Error : Requires manual intervention
}

Error --> Deleting : deleteVolume()

note right of Creating
    Simulated async creation
    with 1 second delay
end note

note right of InUse
    Cannot delete while attached
    Must detach first
end note

@enduml
```

### State Diagram: Bucket Lifecycle

```plantuml
@startuml
!theme plain

[*] --> Active : createBucket()

state Active {
    Active : status = "active"
    Active : objectCount = 0+
    Active : Can store objects
    Active : Can be queried
}

Active --> Deleted : deleteBucket()\n(if objectCount == 0)

Active --> Active : deleteBucket() fails\n(if objectCount > 0)

state Deleted {
    Deleted : Bucket removed
}

Deleted --> [*]

note right of Active
    Bucket cannot be deleted
    if it contains objects
    (objectCount > 0)
end note

@enduml
```

### Use Case Diagram

```plantuml
@startuml
!theme plain
left to right direction

actor "Compute Service" as Compute
actor "Application" as App
actor "Backup Service" as Backup
actor "Administrator" as Admin

rectangle "Storage Service API" {
    
    package "Block Volume Management" {
        usecase "Create Volume" as UC1
        usecase "List Volumes" as UC2
        usecase "Get Volume Details" as UC3
        usecase "Delete Volume" as UC4
        usecase "Attach Volume" as UC5
        usecase "Detach Volume" as UC6
        usecase "Check Volume Status" as UC7
    }
    
    package "Snapshot Management" {
        usecase "Create Snapshot" as UC8
        usecase "List Snapshots" as UC9
        usecase "Restore from Snapshot" as UC10
    }
    
    package "Object Storage" {
        usecase "Create Bucket" as UC11
        usecase "List Buckets" as UC12
        usecase "Get Bucket Details" as UC13
        usecase "Delete Bucket" as UC14
        usecase "Upload Object" as UC15
        usecase "Download Object" as UC16
    }
    
    package "System" {
        usecase "Health Check" as UC17
        usecase "Tenant Isolation" as UC18
        usecase "Capacity Management" as UC19
    }
}

' Volume relationships
Compute --> UC1
Compute --> UC2
Compute --> UC3
Compute --> UC4
Compute --> UC5
Compute --> UC6
UC3 ..> UC7 : <<include>>

' Snapshot relationships
Backup --> UC8
Backup --> UC9
Backup --> UC10
UC8 ..> UC3 : <<include>>

' Bucket relationships
App --> UC11
App --> UC12
App --> UC13
App --> UC14
App --> UC15
App --> UC16

' System relationships
Admin --> UC17
UC1 ..> UC18 : <<include>>
UC11 ..> UC18 : <<include>>
UC1 ..> UC19 : <<include>>
UC11 ..> UC19 : <<include>>

note right of UC1
    Volumes are created
    asynchronously with
    status tracking
end note

note right of UC4
    Cannot delete volume
    while attached to
    an instance
end note

note right of UC8
    Snapshots provide
    point-in-time backups
    for disaster recovery
end note

note bottom of UC14
    Bucket must be empty
    (objectCount == 0)
    before deletion
end note

note bottom of UC18
    All operations filter
    by tenant ID from
    X-Tenant-ID header
end note

@enduml
```

### Component Diagram

```plantuml
@startuml
!theme plain

package "Storage Service Container" {
    component [app.d\nMain Entry Point] as App
    
    package "Service Layer" {
        component [StorageService] as Service
        note right of Service
            Routes:
            - /health
            - /api/v1/storage/volumes/*
            - /api/v1/storage/buckets/*
        end note
    }
    
    package "Entity Models" {
        component [VolumeEntity] as Volume
        component [BucketEntity] as Bucket
    }
    
    package "Data Stores" {
        database "volumes{}\n(by ID)" as VolumeStore
        database "buckets{}\n(by ID)" as BucketStore
    }
    
    App --> Service : initializes
    Service --> Volume : creates/uses
    Service --> Bucket : creates/uses
    Service --> VolumeStore : read/write
    Service --> BucketStore : read/write
}

' External Dependencies
component [vibe.d HTTP Server\nPort: 8082] as Vibe
component [uim.iaas.core\nIaasEntity] as Core
component [API Gateway\nPort: 8080] as Gateway

App ..> Vibe : uses
Service ..> Vibe : URLRouter
Volume --|> Core : extends
Bucket --|> Core : extends

' External Services
cloud "IaaS Microservices" {
    component [Compute Service\n:8081] as Compute
    component [Monitoring Service\n:8085] as Monitor
}

cloud "Client Applications" {
    component [Web Applications] as WebApp
    component [Backup Systems] as BackupSys
}

' Interactions
Gateway --> App : HTTP/REST\n+ X-Tenant-ID
Compute --> Gateway : Volume attach/detach\nVolume lifecycle
BackupSys --> Gateway : Snapshot creation\nBackup operations
WebApp --> Gateway : Bucket operations\nObject storage

Service --> Monitor : POST metrics\nStorage usage stats

note right of Gateway
    Gateway adds tenant context
    via X-Tenant-ID header
end note

note bottom of VolumeStore
    In-Memory Storage:
    - Fast access
    - No persistence
    - Status: creating → available
end note

note bottom of BucketStore
    In-Memory Storage:
    - Object count tracking
    - Size tracking (bytes)
end note

@enduml
```

### Activity Diagram: Volume Attach/Detach Flow

```plantuml
@startuml
!theme plain

|Compute Service|
start
:Request volume attachment;

|Storage Service|
:Receive POST /volumes/:id/attach\nwith instanceId;

:Extract volume ID from URL;

:Extract instanceId from body;

if (Volume exists?) then (yes)
    if (Volume status == "available"?) then (yes)
        :Update volume:\n- status = "in-use"\n- attachedTo = instanceId\n- updatedAt = now();
        
        :Return 200 OK with volume data;
        
        |Compute Service|
        :Mount volume to instance;
        :Volume ready for use;
        
        ...Instance uses volume for data storage...
        
        :Request volume detachment;
        
        |Storage Service|
        :Receive POST /volumes/:id/detach;
        
        if (Volume exists?) then (yes)
            :Update volume:\n- status = "available"\n- attachedTo = ""\n- updatedAt = now();
            
            :Return 200 OK;
            
            |Compute Service|
            :Unmount volume from instance;
            :Volume detached successfully;
            
        else (no)
            :Return 404 Not Found;
        endif
        
    else (no, in-use or other)
        :Return 400 Bad Request\n"Volume not available";
    endif
else (no)
    :Return 404 Not Found\n"Volume not found";
endif

stop

@enduml
```

### Activity Diagram: Bucket Deletion Flow

```plantuml
@startuml
!theme plain

start

:Receive DELETE /buckets/:id request;

:Extract bucket ID from URL;

:Extract tenant ID from X-Tenant-ID header;

if (Bucket exists?) then (yes)
    if (Bucket.tenantId == tenant?) then (yes)
        if (Bucket.objectCount == 0?) then (yes)
            :Remove bucket from storage;
            
            :Return 204 No Content;
            
            stop
            
        else (no, has objects)
            :Return 400 Bad Request;
            note right
                Error: "Bucket is not empty"
                User must delete all objects first
            end note
            
            stop
        endif
        
    else (no, different tenant)
        :Return 403 Forbidden;
        note right: Access denied
        stop
    endif
    
else (no)
    :Return 404 Not Found;
    note right: Bucket not found
    stop
endif

@enduml
```

## API Endpoints

### Health Check
```http
GET /health
```
Returns service health status.

Response:
```json
{
  "status": "healthy",
  "service": "storage-service"
}
```

### Block Volume Management

#### List Volumes
```http
GET /api/v1/storage/volumes
X-Tenant-ID: your-tenant-id
```

Response: `200 OK`
```json
{
  "volumes": [
    {
      "id": "vol-123",
      "name": "data-volume",
      "tenantId": "tenant-001",
      "type": "block",
      "sizeGB": 100,
      "status": "available",
      "attachedTo": "",
      "createdAt": 1640995200,
      "updatedAt": 1640995200,
      "metadata": {}
    }
  ]
}
```

#### Get Volume by ID
```http
GET /api/v1/storage/volumes/{volume-id}
X-Tenant-ID: your-tenant-id
```

#### Create Volume
```http
POST /api/v1/storage/volumes
Content-Type: application/json
X-Tenant-ID: your-tenant-id

{
  "name": "data-volume",
  "type": "block",
  "sizeGB": 100,
  "metadata": {
    "purpose": "database",
    "tier": "performance"
  }
}
```

Response: `201 Created`
```json
{
  "id": "vol-123",
  "name": "data-volume",
  "tenantId": "tenant-001",
  "type": "block",
  "sizeGB": 100,
  "status": "creating",
  "attachedTo": "",
  "createdAt": 1640995200,
  "updatedAt": 1640995200,
  "metadata": {
    "purpose": "database",
    "tier": "performance"
  }
}
```

**Note:** Volume status will change from `creating` to `available` after ~1 second (async provisioning).

#### Delete Volume
```http
DELETE /api/v1/storage/volumes/{volume-id}
X-Tenant-ID: your-tenant-id
```

Response: `204 No Content`

**Error Cases:**
- `404 Not Found`: Volume doesn't exist
- `403 Forbidden`: Volume belongs to different tenant
- `400 Bad Request`: Volume is currently attached (status: "in-use")

#### Attach Volume to Instance
```http
POST /api/v1/storage/volumes/{volume-id}/attach
Content-Type: application/json
X-Tenant-ID: your-tenant-id

{
  "instanceId": "inst-456"
}
```

Response: `200 OK`
```json
{
  "id": "vol-123",
  "status": "in-use",
  "attachedTo": "inst-456",
  "updatedAt": 1640995300
}
```

#### Detach Volume from Instance
```http
POST /api/v1/storage/volumes/{volume-id}/detach
X-Tenant-ID: your-tenant-id
```

Response: `200 OK`
```json
{
  "id": "vol-123",
  "status": "available",
  "attachedTo": "",
  "updatedAt": 1640995400
}
```

#### Create Volume Snapshot
```http
POST /api/v1/storage/volumes/{volume-id}/snapshot
Content-Type: application/json
X-Tenant-ID: your-tenant-id

{
  "name": "daily-backup-2026-01-23"
}
```

Response: `201 Created`
```json
{
  "id": "snap-789",
  "volumeId": "vol-123",
  "name": "daily-backup-2026-01-23",
  "status": "creating",
  "createdAt": 1640995500
}
```

### Object Storage (Buckets)

#### List Buckets
```http
GET /api/v1/storage/buckets
X-Tenant-ID: your-tenant-id
```

Response: `200 OK`
```json
{
  "buckets": [
    {
      "id": "bkt-456",
      "name": "my-data-bucket",
      "tenantId": "tenant-001",
      "region": "us-east",
      "objectCount": 0,
      "totalSizeBytes": 0,
      "status": "active",
      "createdAt": 1640995200,
      "metadata": {}
    }
  ]
}
```

#### Get Bucket by ID
```http
GET /api/v1/storage/buckets/{bucket-id}
X-Tenant-ID: your-tenant-id
```

#### Create Bucket
```http
POST /api/v1/storage/buckets
Content-Type: application/json
X-Tenant-ID: your-tenant-id

{
  "name": "my-data-bucket",
  "region": "us-east",
  "metadata": {
    "project": "analytics",
    "department": "engineering"
  }
}
```

Response: `201 Created`
```json
{
  "id": "bkt-456",
  "name": "my-data-bucket",
  "tenantId": "tenant-001",
  "region": "us-east",
  "objectCount": 0,
  "totalSizeBytes": 0,
  "status": "active",
  "createdAt": 1640995200,
  "metadata": {
    "project": "analytics",
    "department": "engineering"
  }
}
```

#### Delete Bucket
```http
DELETE /api/v1/storage/buckets/{bucket-id}
X-Tenant-ID: your-tenant-id
```

Response: `204 No Content`

**Error Cases:**
- `404 Not Found`: Bucket doesn't exist
- `400 Bad Request`: Bucket is not empty (objectCount > 0)

## Multi-Tenancy

The Storage Service implements **complete tenant isolation**:

- **Tenant Identification**: Via `X-Tenant-ID` HTTP header
- **Volume Isolation**: Each tenant has separate volumes
- **Bucket Isolation**: Object storage buckets are scoped per tenant
- **Access Control**: Prevents cross-tenant access to storage resources
- **Default Tenant**: Falls back to "default" if no header provided

### Multi-Tenant Example

Tenant A creates their volume:
```bash
curl -X POST http://localhost:8082/api/v1/storage/volumes \
  -H "X-Tenant-ID: tenant-a" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "tenant-a-volume",
    "sizeGB": 50
  }'
```

Tenant B creates their volume (completely isolated):
```bash
curl -X POST http://localhost:8082/api/v1/storage/volumes \
  -H "X-Tenant-ID: tenant-b" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "tenant-b-volume",
    "sizeGB": 100
  }'
```

Tenants cannot see or access each other's storage resources.

## Data Model

### Volume Entity
- **id**: Unique identifier (UUID)
- **name**: Human-readable volume name
- **tenantId**: Tenant isolation identifier
- **type**: Storage type ("block" or "object")
- **sizeGB**: Volume size in gigabytes
- **status**: Volume state (available, in-use, creating, deleting, error)
- **attachedTo**: Instance ID if attached, empty string otherwise
- **createdAt**: Creation timestamp
- **updatedAt**: Last update timestamp
- **metadata**: Key-value pairs for additional data

### Bucket Entity
- **id**: Unique identifier (UUID)
- **name**: Bucket name
- **tenantId**: Tenant identifier
- **region**: Geographic region (e.g., "us-east", "eu-west")
- **objectCount**: Number of objects in bucket
- **totalSizeBytes**: Total size of all objects in bytes
- **status**: Bucket status (active, deleted)
- **createdAt**: Creation timestamp
- **metadata**: Additional metadata

### Volume Status Values

- **creating**: Volume is being provisioned (async operation in progress)
- **available**: Volume is ready to be attached to an instance
- **in-use**: Volume is attached to a compute instance
- **deleting**: Volume is being removed
- **error**: An error occurred during provisioning or operation

## Configuration

### Port Configuration
Default port: **8082**

Configured in [app.d](source/app.d):
```d
auto settings = new HTTPServerSettings;
settings.port = 8082;
settings.bindAddresses = ["0.0.0.0"];
```

### Service Settings
| Setting | Default | Description |
|---------|---------|-------------|
| Port | 8082 | HTTP server port |
| Bind Address | 0.0.0.0 | Network interface to bind |
| Async Creation Delay | 1 second | Simulated volume provisioning time |
| Tenant Header | X-Tenant-ID | HTTP header for tenant identification |

### Storage Constraints
- **Volume Attachment**: Only one instance per volume
- **Volume Deletion**: Cannot delete attached volumes (status must not be "in-use")
- **Bucket Deletion**: Cannot delete non-empty buckets (objectCount must be 0)

## Building and Running

### Prerequisites
- D compiler (DMD, LDC, or GDC)
- DUB package manager
- vibe.d framework (automatically installed via DUB)

### Build with DUB
```bash
cd storage
dub build
```

For release build with optimizations:
```bash
dub build --build=release
```

### Run the Service
```bash
./uim-iaas-storage
```

Or directly with DUB:
```bash
dub run
```

The service will start and listen on port 8082:
```
Storage Service starting on port 8082
```

### Run with Docker
Build the Docker image:
```bash
docker build -t uim-iaas-storage:latest .
```

Run the container:
```bash
docker run -p 8082:8082 uim-iaas-storage:latest
```

### Run with Docker Compose
From the project root:
```bash
docker-compose up storage
```

Run in detached mode:
```bash
docker-compose up -d storage
```

View logs:
```bash
docker-compose logs -f storage
```

## Dependencies

Defined in [dub.sdl](dub.sdl):

- **vibe-d**: Web framework and HTTP server
- **uim-iaas-core**: Core entities and utilities

## Integration with Other Services

### Compute Service Integration
Virtual machines need storage volumes:

```d
// Compute service creates and attaches volume
auto volumeResponse = requestHTTP("http://storage:8082/api/v1/storage/volumes",
    (scope req) {
        req.method = HTTPMethod.POST;
        req.headers["X-Tenant-ID"] = tenantId;
        req.writeJsonBody([
            "name": "vm-root-disk",
            "sizeGB": 50
        ]);
    }
);

auto volumeId = volumeResponse.json["id"].get!string;

// Wait for volume to be available (status: "creating" -> "available")
// Then attach to instance
requestHTTP("http://storage:8082/api/v1/storage/volumes/" ~ volumeId ~ "/attach",
    (scope req) {
        req.method = HTTPMethod.POST;
        req.headers["X-Tenant-ID"] = tenantId;
        req.writeJsonBody(["instanceId": instanceId]);
    }
);
```

### Backup Service Integration
Create snapshots for disaster recovery:

```d
// Backup service creates snapshot
auto snapshotResponse = requestHTTP(
    "http://storage:8082/api/v1/storage/volumes/" ~ volumeId ~ "/snapshot",
    (scope req) {
        req.method = HTTPMethod.POST;
        req.headers["X-Tenant-ID"] = tenantId;
        req.writeJsonBody([
            "name": "daily-backup-" ~ getCurrentDate()
        ]);
    }
);
```

### Monitoring Integration
Report storage metrics:

```d
// Report volume creation metric
requestHTTP("http://monitoring:8085/api/v1/monitoring/metrics",
    (scope req) {
        req.method = HTTPMethod.POST;
        req.headers["X-Tenant-ID"] = tenantId;
        req.writeJsonBody([
            "name": "volume_created",
            "type": "counter",
            "value": 1,
            "labels": [
                "service": "storage",
                "type": "block",
                "sizeGB": sizeGB.to!string
            ]
        ]);
    }
);
```

## Storage Best Practices

### Volume Management
1. **Right-Sizing**: Choose appropriate volume sizes based on workload
2. **Status Monitoring**: Check volume status before operations
3. **Cleanup**: Detach and delete unused volumes to free resources
4. **Snapshots**: Regular snapshots for data protection

### Bucket Management
1. **Empty Before Delete**: Remove all objects before deleting buckets
2. **Regional Placement**: Choose regions close to your applications
3. **Naming Conventions**: Use descriptive, consistent bucket names
4. **Capacity Planning**: Monitor object count and total size

### Common Storage Patterns

**Database Volume:**
```bash
curl -X POST http://localhost:8082/api/v1/storage/volumes \
  -H "X-Tenant-ID: production" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "postgres-data",
    "type": "block",
    "sizeGB": 200,
    "metadata": {
      "purpose": "database",
      "database": "postgresql"
    }
  }'
```

**Application Data Bucket:**
```bash
curl -X POST http://localhost:8082/api/v1/storage/buckets \
  -H "X-Tenant-ID: production" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "app-uploads",
    "region": "us-east",
    "metadata": {
      "application": "web-app",
      "content-type": "user-uploads"
    }
  }'
```

## Validation and Constraints

### Volume Operations
- **Cannot attach**: Volume must be in "available" status
- **Cannot delete**: Volume must not be in "in-use" status (must detach first)
- **Cannot detach**: Only applicable if volume is attached

### Bucket Operations
- **Cannot delete**: Bucket must be empty (objectCount == 0)
- **Name uniqueness**: Bucket names should be unique per tenant

## Performance Considerations

- **In-Memory Storage**: Fast access but no persistence
- **No Persistence**: Data lost on restart (development mode)
- **Async Creation**: Volume provisioning simulated with 1-second delay
- **Scalability**: Limited by single-instance memory
- **Future Enhancement**: Database backend for production

## Future Enhancements

1. **Persistent Storage**: PostgreSQL/database integration
2. **Volume Encryption**: At-rest and in-transit encryption
3. **Volume Replication**: Multi-region volume replication
4. **Object Operations**: Full object upload/download/delete APIs
5. **Bucket Policies**: Fine-grained access control
6. **Storage Quotas**: Per-tenant storage limits
7. **Volume Resizing**: Expand volume capacity
8. **Snapshot Management**: List, restore, and delete snapshots
9. **Storage Classes**: Performance vs. capacity tiers
10. **Lifecycle Policies**: Automatic archival and deletion
11. **Volume Cloning**: Create volume from existing volume
12. **Multi-Attach**: Shared volumes for multiple instances

## Troubleshooting

### Volume Not Available
**Problem**: Volume stuck in "creating" status

**Solutions**:
1. Wait for async creation to complete (~1 second)
2. Check service logs for errors
3. Query volume status: `GET /volumes/{id}`

### Cannot Attach Volume
**Problem**: Attach operation fails

**Solutions**:
1. Verify volume status is "available":
   ```bash
   curl -H "X-Tenant-ID: tenant" \
     http://localhost:8082/api/v1/storage/volumes/{volume-id}
   ```
2. Check if volume is already attached to another instance
3. Verify instanceId is correct

### Cannot Delete Volume
**Problem**: Delete operation returns 400 Bad Request

**Solutions**:
1. Detach volume first:
   ```bash
   curl -X POST http://localhost:8082/api/v1/storage/volumes/{id}/detach \
     -H "X-Tenant-ID: tenant"
   ```
2. Wait for status to change to "available"
3. Then delete the volume

### Cannot Delete Bucket
**Problem**: Bucket deletion fails with "Bucket is not empty"

**Solutions**:
1. Check object count:
   ```bash
   curl -H "X-Tenant-ID: tenant" \
     http://localhost:8082/api/v1/storage/buckets/{bucket-id}
   ```
2. Delete all objects in the bucket first
3. Verify objectCount is 0
4. Then delete the bucket

### Service Not Starting
**Problem**: Service fails to start or exits immediately

**Solutions**:
1. Check port availability:
   ```bash
   netstat -tuln | grep 8082
   ```
2. Check dependencies:
   ```bash
   dub describe
   ```
3. View detailed logs:
   ```bash
   dub run --verbose
   ```

## Testing

### Manual Testing with cURL

#### 1. Health Check
```bash
curl http://localhost:8082/health
```

#### 2. Create a Volume
```bash
VOLUME_ID=$(curl -X POST http://localhost:8082/api/v1/storage/volumes \
  -H "X-Tenant-ID: test-tenant" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test-volume",
    "type": "block",
    "sizeGB": 50
  }' | jq -r '.id')

echo "Created volume: $VOLUME_ID"
```

#### 3. Wait for Volume to be Available
```bash
# Wait 2 seconds for async creation
sleep 2

# Check status
curl -H "X-Tenant-ID: test-tenant" \
  http://localhost:8082/api/v1/storage/volumes/$VOLUME_ID
```

#### 4. Attach Volume
```bash
curl -X POST http://localhost:8082/api/v1/storage/volumes/$VOLUME_ID/attach \
  -H "X-Tenant-ID: test-tenant" \
  -H "Content-Type: application/json" \
  -d '{"instanceId": "inst-test-123"}'
```

#### 5. Create Snapshot
```bash
curl -X POST http://localhost:8082/api/v1/storage/volumes/$VOLUME_ID/snapshot \
  -H "X-Tenant-ID: test-tenant" \
  -H "Content-Type: application/json" \
  -d '{"name": "test-snapshot"}'
```

#### 6. Detach Volume
```bash
curl -X POST http://localhost:8082/api/v1/storage/volumes/$VOLUME_ID/detach \
  -H "X-Tenant-ID: test-tenant"
```

#### 7. Delete Volume
```bash
curl -X DELETE http://localhost:8082/api/v1/storage/volumes/$VOLUME_ID \
  -H "X-Tenant-ID: test-tenant"
```

#### 8. Test Object Storage
```bash
# Create bucket
BUCKET_ID=$(curl -X POST http://localhost:8082/api/v1/storage/buckets \
  -H "X-Tenant-ID: test-tenant" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test-bucket",
    "region": "us-east"
  }' | jq -r '.id')

echo "Created bucket: $BUCKET_ID"

# List buckets
curl -H "X-Tenant-ID: test-tenant" \
  http://localhost:8082/api/v1/storage/buckets

# Delete bucket
curl -X DELETE http://localhost:8082/api/v1/storage/buckets/$BUCKET_ID \
  -H "X-Tenant-ID: test-tenant"
```

### Integration Testing

Test with compute service:
```bash
# Start all services
docker-compose up -d

# Create volume via storage service
VOLUME_ID=$(curl -X POST http://localhost:8082/api/v1/storage/volumes \
  -H "X-Tenant-ID: integration-test" \
  -H "Content-Type: application/json" \
  -d '{"name": "integration-volume", "sizeGB": 50}' | jq -r '.id')

# Wait for availability
sleep 2

# Create compute instance
INSTANCE_ID=$(curl -X POST http://localhost:8081/api/v1/compute/instances \
  -H "X-Tenant-ID: integration-test" \
  -H "Content-Type: application/json" \
  -d '{"name": "test-vm", "flavor": "small"}' | jq -r '.id')

# Attach volume to instance
curl -X POST http://localhost:8082/api/v1/storage/volumes/$VOLUME_ID/attach \
  -H "X-Tenant-ID: integration-test" \
  -H "Content-Type: application/json" \
  -d "{\"instanceId\": \"$INSTANCE_ID\"}"
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Volume not found` | Invalid volume ID | Check volume ID and tenant |
| `Volume is currently attached` | Trying to delete attached volume | Detach first, then delete |
| `Bucket is not empty` | Bucket has objects | Delete all objects first |
| `Access denied` | Wrong tenant ID | Use correct X-Tenant-ID header |
| `Address already in use` | Port 8082 occupied | Stop conflicting service |

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

**Storage Service Version**: 1.0.0  
**NAF Version**: v4  
**Last Updated**: January 2026
