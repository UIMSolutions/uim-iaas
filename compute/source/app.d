module app;

import vibe.vibe;
import std.stdio;
import std.uuid;
import std.datetime;

void main() {
    auto settings = new HTTPServerSettings;
    settings.port = 8081;
    settings.bindAddresses = ["0.0.0.0"];
    
    auto router = new URLRouter;
    auto service = new ComputeService();
    service.setupRoutes(router);
    
    logInfo("Compute Service starting on port %d", settings.port);
    listenHTTP(settings, router);
    
    runApplication();
}
