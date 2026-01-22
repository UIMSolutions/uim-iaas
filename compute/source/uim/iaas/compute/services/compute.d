/**
 * Compute Service - Manages virtual machines and container instances with multi-tenancy
 */
class ComputeService {
    private Instance[string] instances;

    void setupRoutes(URLRouter router) {
        router.get("/health", &healthCheck);
        router.get("/api/v1/compute/instances", &listInstances);
        router.get("/api/v1/compute/instances/:id", &getInstance);
        router.post("/api/v1/compute/instances", &createInstance);
        router.delete_("/api/v1/compute/instances/:id", &deleteInstance);
        router.post("/api/v1/compute/instances/:id/start", &startInstance);
        router.post("/api/v1/compute/instances/:id/stop", &stopInstance);
        router.post("/api/v1/compute/instances/:id/restart", &restartInstance);
        router.get("/api/v1/compute/flavors", &listFlavors);
    }

    void healthCheck(HTTPServerRequest req, HTTPServerResponse res) {
        res.writeJsonBody(["status": "healthy", "service": "compute-service"]);
    }

    void listInstances(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        JSONValue[] instanceList;
        foreach (instance; instances) {
            // Only show instances from the same tenant
            if (instance.tenantId == tenantId) {
                instanceList ~= serializeInstance(instance);
            }
        }
        res.writeJsonBody(["instances": instanceList]);
    }

    void getInstance(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        auto tenantId = getTenantIdFromRequest(req);
        
        if (id !in instances) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Instance not found"]);
            return;
        }
        
        // Verify tenant ownership
        if (instances[id].tenantId != tenantId) {
            res.statusCode = HTTPStatus.forbidden;
            res.writeJsonBody(["error": "Access denied"]);
            return;
        }
        
        res.writeJsonBody(serializeInstance(instances[id]));
    }

    void createInstance(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        auto instance = Instance();
        instance.id = randomUUID().toString();
        instance.name = data["name"].str;
        instance.tenantId = tenantId;
        instance.type = data["type"].str;
        instance.flavor = data["flavor"].get!string;
        instance.imageId = data["imageId"].get!string;
        instance.status = "creating";
        instance.createdAt = Clock.currTime().toUnixTime();
        instance.updatedAt = instance.createdAt;
        
        if ("metadata" in data && data["metadata"].type == Json.Type.object) {
            foreach (string key, value; data["metadata"].byKeyValue) {
                instance.metadata[key] = value.get!string;
            }
        }
        
        if ("networkIds" in data) {
            foreach (netId; data["networkIds"]) {
                instance.networkIds ~= netId.get!string;
            }
        }
        
        if ("volumeIds" in data) {
            foreach (volId; data["volumeIds"]) {
                instance.volumeIds ~= volId.get!string;
            }
        }
        
        instances[instance.id] = instance;
        
        // Simulate async creation
        runTask({
            sleep(2.seconds);
            instances[instance.id].status = "running";
            instances[instance.id].updatedAt = Clock.currTime().toUnixTime();
            logInfo("Instance %s is now running", instance.id);
        });
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeInstance(instance));
    }

    void deleteInstance(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        auto tenantId = getTenantIdFromRequest(req);
        
        if (id !in instances) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Instance not found"]);
            return;
        }
        
        // Verify tenant ownership
        if (instances[id].tenantId != tenantId) {
            res.statusCode = HTTPStatus.forbidden;
            res.writeJsonBody(["error": "Access denied"]);
            return;
        }
        
        instances.remove(id);
        res.statusCode = HTTPStatus.noContent;
        res.writeVoidBody();
    }

    void startInstance(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        auto tenantId = getTenantIdFromRequest(req);
        
        if (id !in instances) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Instance not found"]);
            return;
        }
        
        // Verify tenant ownership
        if (instances[id].tenantId != tenantId) {
            res.statusCode = HTTPStatus.forbidden;
            res.writeJsonBody(["error": "Access denied"]);
            return;
        }
        
        instances[id].status = "running";
        instances[id].updatedAt = Clock.currTime().toUnixTime();
        res.writeJsonBody(serializeInstance(instances[id]));
    }

    void stopInstance(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        auto tenantId = getTenantIdFromRequest(req);
        
        if (id !in instances) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Instance not found"]);
            return;
        }
        
        // Verify tenant ownership
        if (instances[id].tenantId != tenantId) {
            res.statusCode = HTTPStatus.forbidden;
            res.writeJsonBody(["error": "Access denied"]);
            return;
        }
        
        instances[id].status = "stopped";
        instances[id].updatedAt = Clock.currTime().toUnixTime();
        res.writeJsonBody(serializeInstance(instances[id]));
    }

    void restartInstance(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        auto tenantId = getTenantIdFromRequest(req);
        
        if (id !in instances) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Instance not found"]);
            return;
        }
        
        // Verify tenant ownership
        if (instances[id].tenantId != tenantId) {
            res.statusCode = HTTPStatus.forbidden;
            res.writeJsonBody(["error": "Access denied"]);
            return;
        }
        
        instances[id].status = "restarting";
        instances[id].updatedAt = Clock.currTime().toUnixTime();
        
        runTask({
            sleep(1.seconds);
            instances[id].status = "running";
            instances[id].updatedAt = Clock.currTime().toUnixTime();
        });
        
        res.writeJsonBody(serializeInstance(instances[id]));
    }

    string getTenantIdFromRequest(HTTPServerRequest req) {
        // Extract tenant ID from X-Tenant-ID header (set by API Gateway after auth)
        if ("X-Tenant-ID" in req.headers) {
            return req.headers["X-Tenant-ID"];
        }
        return "default";
    }

    void listFlavors(HTTPServerRequest req, HTTPServerResponse res) {
        auto flavors = [
            ["name": "small", "vcpus": 1, "ram": 1024, "disk": 10],
            ["name": "medium", "vcpus": 2, "ram": 4096, "disk": 40],
            ["name": "large", "vcpus": 4, "ram": 8192, "disk": 80],
            ["name": "xlarge", "vcpus": 8, "ram": 16384, "disk": 160]
        ];
        res.writeJsonBody(["flavors": flavors]);
    }

    Json serializeInstance(Instance instance) {
        return Json([
            "id": Json(instance.id),
            "name": Json(instance.name),
            "tenantId": Json(instance.tenantId),
            "type": Json(instance.type),
            "flavor": Json(instance.flavor),
            "status": Json(instance.status),
            "imageId": Json(instance.imageId),
            "networkIds": serializeToJson(instance.networkIds),
            "volumeIds": serializeToJson(instance.volumeIds),
            "createdAt": Json(instance.createdAt),
            "updatedAt": Json(instance.updatedAt),
            "metadata": serializeToJson(instance.metadata)
        ]);
    }
}
