module objectstore.api.router;

import vibe.vibe;
import objectstore.storage.manager;
import objectstore.config;
import objectstore.api.auth;
import objectstore.models;

URLRouter createAPIRouter(StorageManager storageManager, Config config)
{
    auto router = new URLRouter;

    // Health check endpoint (no auth)
    router.get("/health", (HTTPServerRequest req, HTTPServerResponse res) {
        res.writeJsonBody([
            "status": "healthy",
            "service": "objectstore",
            "version": "1.0.0"
        ]);
    });

    // API v1 endpoints
    auto apiRouter = new URLRouter;
    
    // Authentication middleware for API routes
    if (config.enableAuth)
    {
        apiRouter.any("*", &authMiddleware(config.authToken));
    }

    // Container operations
    apiRouter.get("/containers", &listContainers(storageManager));
    apiRouter.post("/containers/:name", &createContainer(storageManager));
    apiRouter.delete_("/containers/:name", &deleteContainer(storageManager));
    apiRouter.get("/containers/:name", &getContainer(storageManager));

    // Object operations
    apiRouter.get("/containers/:container/objects", &listObjects(storageManager));
    apiRouter.put("/containers/:container/objects/:object", &uploadObject(storageManager));
    apiRouter.get("/containers/:container/objects/:object", &downloadObject(storageManager));
    apiRouter.delete_("/containers/:container/objects/:object", &deleteObject(storageManager));
    apiRouter.get("/containers/:container/objects/:object/metadata", &getObjectMetadata(storageManager));

    // Service keys operations (credentials)
    apiRouter.post("/containers/:name/keys", &createServiceKey(storageManager, config));
    apiRouter.get("/containers/:name/keys/:keyname", &getServiceKey(storageManager));
    apiRouter.delete_("/containers/:name/keys/:keyname", &deleteServiceKey(storageManager));

    router.any("/api/v1/*", apiRouter);

    return router;
}

// Container Handlers
HTTPServerRequestDelegate listContainers(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containers = sm.listContainers();
            res.writeJsonBody(["containers": containers]);
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.internalServerError;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate createContainer(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["name"];
            auto container = sm.createContainer(containerName);
            res.statusCode = HTTPStatus.created;
            res.writeJsonBody(container.toJson());
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate deleteContainer(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["name"];
            sm.deleteContainer(containerName);
            res.statusCode = HTTPStatus.noContent;
            res.writeBody("");
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate getContainer(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["name"];
            auto container = sm.getContainer(containerName);
            res.writeJsonBody(container.toJson());
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

// Object Handlers
HTTPServerRequestDelegate listObjects(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["container"];
            auto objects = sm.listObjects(containerName);
            res.writeJsonBody(["objects": objects]);
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate uploadObject(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["container"];
            auto objectName = req.params["object"];
            
            // Get content type
            string contentType = req.headers.get("Content-Type", "application/octet-stream");
            
            // Read body as bytes
            auto bodyData = req.bodyReader.readAll();
            
            auto obj = sm.uploadObject(containerName, objectName, bodyData, contentType);
            res.statusCode = HTTPStatus.created;
            res.writeJsonBody(obj.toJson());
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate downloadObject(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["container"];
            auto objectName = req.params["object"];
            
            auto result = sm.downloadObject(containerName, objectName);
            
            res.headers["Content-Type"] = result.contentType;
            res.headers["Content-Length"] = result.data.length.to!string;
            res.writeBody(result.data, result.contentType);
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate deleteObject(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["container"];
            auto objectName = req.params["object"];
            
            sm.deleteObject(containerName, objectName);
            res.statusCode = HTTPStatus.noContent;
            res.writeBody("");
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate getObjectMetadata(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["container"];
            auto objectName = req.params["object"];
            
            auto metadata = sm.getObjectMetadata(containerName, objectName);
            res.writeJsonBody(metadata.toJson());
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

// Service Key Handlers
HTTPServerRequestDelegate createServiceKey(StorageManager sm, Config config)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["name"];
            auto keyName = req.json["keyName"].get!string;
            
            auto serviceKey = sm.createServiceKey(containerName, keyName);
            res.statusCode = HTTPStatus.created;
            res.writeJsonBody(serviceKey.toJson());
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate getServiceKey(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["name"];
            auto keyName = req.params["keyname"];
            
            auto serviceKey = sm.getServiceKey(containerName, keyName);
            res.writeJsonBody(serviceKey.toJson());
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}

HTTPServerRequestDelegate deleteServiceKey(StorageManager sm)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        try
        {
            auto containerName = req.params["name"];
            auto keyName = req.params["keyname"];
            
            sm.deleteServiceKey(containerName, keyName);
            res.statusCode = HTTPStatus.noContent;
            res.writeBody("");
        }
        catch (Exception e)
        {
            res.statusCode = HTTPStatus.badRequest;
            res.writeJsonBody(["error": e.msg]);
        }
    };
}
