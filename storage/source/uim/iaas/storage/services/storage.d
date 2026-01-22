module uim.iaas.storage.services.storage;

import uim.iaas.storage;

/**
 * Storage Service - Manages block storage volumes and object storage with multi-tenancy
 */
class StorageService {
    private VolumeEntity[string] volumes;
    private BucketEntity[string] buckets;

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
        
        Json[] volumeList;
        foreach (volume; volumes) {
            if (volume.tenantId == tenantId) {
                volumeList ~= serializeVolume(volume);
            }
        }
        res.writeJsonBody(Json(["volumes": Json(volumeList)]));
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
        
        auto volume = new VolumeEntity();
        volume.id = randomUUID().toString();
        volume.name = data["name"].get!string;
        volume.tenantId = tenantId;
        volume.type = ("type" in data) ? data["type"].get!string : "block";
        volume.sizeGB = data["sizeGB"].get!long;
        volume.status = "creating";
        volume.attachedTo = "";
        volume.createdAt = Clock.currTime().toUnixTime();
        volume.updatedAt = volume.createdAt;
        
        if ("metadata" in data && data["metadata"].type == Json.Type.object) {
            foreach (string key, value; data["metadata"].byKeyValue) {
                volume.metadata(key, value.get!string);
            }
        }
        
        volumes[volume.id] = volume;
        
        // Simulate async creation
        runTask(() nothrow {
            try {
                sleep(1.seconds);
                volumes[volume.id].status = "available";
                volumes[volume.id].updatedAt = Clock.currTime().toUnixTime();
                logInfo("Volume %s is now available", volume.id);
            } catch (Exception e) {
                // Log error but don't crash
            }
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
        auto instanceId = data["instanceId"].get!string;
        
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
        
        auto snapshot = Json([
            "id": Json(snapshotId),
            "volumeId": Json(id),
            "name": Json(data["name"].get!string),
            "status": Json("creating"),
            "createdAt": Json(Clock.currTime().toUnixTime())
        ]);
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(snapshot);
    }

    // Bucket operations
    void listBuckets(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        Json[] bucketList;
        foreach (bucket; buckets) {
            if (bucket.tenantId == tenantId) {
                bucketList ~= serializeBucket(bucket);
            }
        }
        res.writeJsonBody(Json(["buckets": Json(bucketList)]));
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
        
        auto bucket = new BucketEntity();
        bucket.id = randomUUID().toString();
        bucket.name = data["name"].get!string;
        bucket.tenantId = tenantId;
        bucket.region = ("region" in data) ? data["region"].get!string : "default";
        bucket.objectCount = 0;
        bucket.totalSizeBytes = 0;
        bucket.status = "active";
        bucket.createdAt = Clock.currTime().toUnixTime();
        
        if ("metadata" in data && data["metadata"].type == Json.Type.object) {
            foreach (string key, value; data["metadata"].byKeyValue) {
                bucket.metadata(key, value.get!string);
            }
        }
        
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

    Json serializeVolume(VolumeEntity volume) {
        return Json([
            "id": Json(volume.id),
            "name": Json(volume.name),
            "tenantId": Json(volume.tenantId),
            "type": Json(volume.type),
            "sizeGB": Json(volume.sizeGB),
            "status": Json(volume.status),
            "attachedTo": Json(volume.attachedTo),
            "createdAt": Json(volume.createdAt),
            "updatedAt": Json(volume.updatedAt),
            "metadata": serializeToJson(volume.metadata)
        ]);
    }

    Json serializeBucket(BucketEntity bucket) {
        return Json([
            "id": Json(bucket.id),
            "name": Json(bucket.name),
            "tenantId": Json(bucket.tenantId),
            "region": Json(bucket.region),
            "objectCount": Json(bucket.objectCount),
            "totalSizeBytes": Json(bucket.totalSizeBytes),
            "status": Json(bucket.status),
            "createdAt": Json(bucket.createdAt),
            "metadata": serializeToJson(bucket.metadata)
        ]);
    }
}