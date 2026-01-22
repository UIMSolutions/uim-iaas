module app;

import uim.iaas.network;


void main() {
    auto settings = new HTTPServerSettings;
    settings.port = 8083;
    settings.bindAddresses = ["0.0.0.0"];
    
    auto router = new URLRouter;
    auto service = new NetworkService();
    service.setupRoutes(router);
    
    logInfo("Network Service starting on port %d", settings.port);
    listenHTTP(settings, router);
    
    runApplication();
}
