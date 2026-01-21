module app;

import vibe.vibe;
import std.stdio;
import std.json;
import std.uuid;
import std.datetime;

/**
 * Storage Service - Manages block storage volumes and object storage with multi-tenancy
 */

struct Volume {
    string id;
    string name;
    string tenantId;
    string type; // block, object
    long sizeGB;
    string status; // available, in-use, creating, deleting, error
    string attachedTo; // instance ID
    long createdAt;
    long updatedAt;
    JSONValue metadata;
}

struct Bucket {
    string id;
    string name;
    string tenantId;
    string region;
    long objectCount;
    long totalSizeBytes;
    string status;
    long createdAt;
    JSONValue metadata;
}

class StorageService {
    private Volume[string] volumes;
    private Bucket[string] buckets;

    void setupRoutes(URLRouter router) {
        router.get("/health", &healthCheck);
        
        // Volume management
        router.get("/api/v1/storage/volumes", &listVolumes);
        router.get("/api/v1/storage/volumes/:id", &getVolume);
        router.post("/api/v1/storage/volumes", &createVolume);
        router.delete_("/api/v1/storage/volumes/:id", &deleteVolume);
        router.post("/api/v1/storage/volumes/:id/attach", &attachVolume);
        router.post("/api/v1/storage/volumes/:id/detach", &detachVolume);
        router.post("/api/v1/storage/volumes/:id/snapshot", &createSnapshot);
        
        // Object storage (buckets)
        router.get("/api/v1/storage/buckets", &listBuckets);
        router.get("/api/v1/storage/buckets/:id", &getBucket);
        router.post("/api/v1/storage/buckets", &createBucket);
        router.delete_("/api/v1/storage/buckets/:id", &deleteBucket);
    }

    void healthCheck(HTTPServerRequest req, HTTPServerResponse res) {
        res.writeJsonBody(["status": "healthy", "service": "storage-service"]);
    }

    // Volume operations
    void listVolumes(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        JSONValue[] volumeList;
        foreach (volume; volumes) {
            if (volume.tenantId == tenantId) {
                volumeList ~= serializeVolume(volume);
            }
        }
        res.writeJsonBody(["volumes": volumeList]);
    }

    void getVolume(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        auto tenantId = getTenantIdFromRequest(req);
        
        if (id !in volumes) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Volume not found"]);
            return;
        }
        
        if (volumes[id].tenantId != tenantId) {
            res.statusCode = HTTPStatus.forbidden;
            res.writeJsonBody(["error": "Access denied"]);
            return;
        }
        
        res.writeJsonBody(serializeVolume(volumes[id]));
    }

    void createVolume(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        auto volume = Volume();
        volume.id = randomUUID().toString();
        volume.name = data["name"].str;
        volume.tenantId = tenantId;
        volume.type = data.get("type", JSONValue("block")).str;
        volume.sizeGB = data["sizeGB"].integer;
        volume.status = "creating";
        volume.attachedTo = "";
        volume.createdAt = Clock.currTime().toUnixTime();
        volume.updatedAt = volume.createdAt;
        volume.metadata = data.get("metadata", JSONValue(["": ""]));
        
        volumes[volume.id] = volume;
        
        // Simulate async creation
        runTask({
            sleep(1.seconds);
            volumes[volume.id].status = "available";
            volumes[volume.id].updatedAt = Clock.currTime().toUnixTime();
            logInfo("Volume %s is now available", volume.id);
        });
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeVolume(volume));
    }

    void deleteVolume(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        auto tenantId = getTenantIdFromRequest(req);
        
        if (id !in volumes) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Volume not found"]);
            return;
        }
        
        if (volumes[id].tenantId != tenantId) {
            res.statusCode = HTTPStatus.forbidden;
            res.writeJsonBody(["error": "Access denied"]);
            return;
        }
        
        if (volumes[id].status == "in-use") {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": "Volume is currently attached"]);
            return;
        }
        
        volumes.remove(id);
        res.statusCode = HTTPStatus.noContent;
        res.writeVoidBody();
    }

    void attachVolume(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in volumes) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Volume not found"]);
            return;
        }
        
        auto data = req.json;
        auto instanceId = data["instanceId"].str;
        
        volumes[id].status = "in-use";
        volumes[id].attachedTo = instanceId;
        volumes[id].updatedAt = Clock.currTime().toUnixTime();
        
        res.writeJsonBody(serializeVolume(volumes[id]));
    }

    void detachVolume(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in volumes) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Volume not found"]);
            return;
        }
        
        volumes[id].status = "available";
        volumes[id].attachedTo = "";
        volumes[id].updatedAt = Clock.currTime().toUnixTime();
        
        res.writeJsonBody(serializeVolume(volumes[id]));
    }

    void createSnapshot(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in volumes) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Volume not found"]);
            return;
        }
        
        auto data = req.json;
        auto snapshotId = randomUUID().toString();
        
        auto snapshot = JSONValue([
            "id": snapshotId,
            "volumeId": id,
            "name": data["name"].str,
            "status": "creating",
            "createdAt": Clock.currTime().toUnixTime()
        ]);
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(snapshot);
    }

    // Bucket operations
    void listBuckets(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        JSONValue[] bucketList;
        foreach (bucket; buckets) {
            if (bucket.tenantId == tenantId) {
                bucketList ~= serializeBucket(bucket);
            }
        }
        res.writeJsonBody(["buckets": bucketList]);
    }

    void getBucket(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in buckets) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Bucket not found"]);
            return;
        }
        res.writeJsonBody(serializeBucket(buckets[id]));
    }

    void createBucket(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        auto bucket = Bucket();
        bucket.id = randomUUID().toString();
        bucket.name = data["name"].str;
        bucket.tenantId = tenantId;
        bucket.region = data.get("region", JSONValue("default")).str;
        bucket.objectCount = 0;
        bucket.totalSizeBytes = 0;
        bucket.status = "active";
        bucket.createdAt = Clock.currTime().toUnixTime();
        bucket.metadata = data.get("metadata", JSONValue(["": ""]));
        
        buckets[bucket.id] = bucket;
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeBucket(bucket));
    }

    void deleteBucket(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in buckets) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Bucket not found"]);
            return;
        }
        
        if (buckets[id].objectCount > 0) {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": "Bucket is not empty"]);
            return;
        }
        
        buckets.remove(id);
        res.statusCode = HTTPStatus.noContent;
        res.writeVoidBody();
    }

    string getTenantIdFromRequest(HTTPServerRequest req) {
        if ("X-Tenant-ID" in req.headers) {
            return req.headers["X-Tenant-ID"];
        }
        return "default";
    }

    JSONValue serializeVolume(Volume volume) {
        return JSONValue([
            "id": volume.id,
            "name": volume.name,
            "tenantId": volume.tenantId,
            "type": volume.type,
            "sizeGB": volume.sizeGB,
            "status": volume.status,
            "attachedTo": volume.attachedTo,
            "createdAt": volume.createdAt,
            "updatedAt": volume.updatedAt,
            "metadata": volume.metadata
        ]);
    }

    JSONValue serializeBucket(Bucket bucket) {
        return JSONValue([
            "id": bucket.id,
            "name": bucket.name,
            "tenantId": bucket.tenantId,
            "region": bucket.region,
            "objectCount": bucket.objectCount,
            "totalSizeBytes": bucket.totalSizeBytes,
            "status": bucket.status,
            "createdAt": bucket.createdAt,
            "metadata": bucket.metadata
        ]);
    }
}

void main() {
    auto settings = new HTTPServerSettings;
    settings.port = 8082;
    settings.bindAddresses = ["0.0.0.0"];
    
    auto router = new URLRouter;
    auto service = new StorageService();
    service.setupRoutes(router);
    
    logInfo("Storage Service starting on port %d", settings.port);
    listenHTTP(settings, router);
    
    runApplication();
}
