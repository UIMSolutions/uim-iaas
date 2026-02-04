module app;

import vibe.vibe;
import objectstore.api.router;
import objectstore.config;
import objectstore.storage.manager;

shared static this()
{
    // Load configuration
    auto config = Config.load();
    logInfo("Starting Object Store Service on port %d", config.port);
    logInfo("Storage path: %s", config.storagePath);

    // Initialize storage manager
    auto storageManager = new StorageManager(config.storagePath);

    // Setup HTTP server settings
    auto settings = new HTTPServerSettings;
    settings.port = config.port;
    settings.bindAddresses = ["0.0.0.0"];
    settings.errorPageHandler = toDelegate(&errorPage);

    // Create and configure router
    auto router = createAPIRouter(storageManager, config);

    // Start HTTP server
    listenHTTP(settings, router);

    logInfo("Object Store Service is ready and listening on port %d", config.port);
    logInfo("Health check available at: http://localhost:%d/health", config.port);
}

void errorPage(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
{
    res.writeJsonBody([
        "error": error.message,
        "statusCode": error.code
    ]);
}
