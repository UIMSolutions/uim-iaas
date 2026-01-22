module app;

import uim.iaas.monitoring;

void main() {
    auto settings = new HTTPServerSettings;
    settings.port = 8085;
    settings.bindAddresses = ["0.0.0.0"];
    
    auto router = new URLRouter;
    auto service = new MonitoringService();
    service.setupRoutes(router);
    
    logInfo("Monitoring Service starting on port %d", settings.port);
    listenHTTP(settings, router);
    
    runApplication();
}
