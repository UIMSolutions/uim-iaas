module app;

import uim.iaas.storage;



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
