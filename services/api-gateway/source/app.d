module app;

import vibe.vibe;
import std.stdio;
import std.json;

/**
 * API Gateway Service - Entry point for all IaaS platform requests
 * Routes requests to appropriate microservices
 */

class ApiGateway {
    private {
        string computeServiceUrl = "http://compute-service:8081";
        string storageServiceUrl = "http://storage-service:8082";
        string networkServiceUrl = "http://network-service:8083";
        string authServiceUrl = "http://auth-service:8084";
        string monitoringServiceUrl = "http://monitoring-service:8085";
    }

    void setupRoutes(URLRouter router) {
        // Health check
        router.get("/health", &healthCheck);
        
        // Compute service routes
        router.any("/api/v1/compute/*", &proxyToCompute);
        
        // Storage service routes
        router.any("/api/v1/storage/*", &proxyToStorage);
        
        // Network service routes
        router.any("/api/v1/network/*", &proxyToNetwork);
        
        // Auth service routes
        router.any("/api/v1/auth/*", &proxyToAuth);
        
        // Monitoring service routes
        router.any("/api/v1/monitoring/*", &proxyToMonitoring);
        
        // Platform status
        router.get("/api/v1/status", &getPlatformStatus);
    }

    void healthCheck(HTTPServerRequest req, HTTPServerResponse res) {
        res.writeJsonBody(["status": "healthy", "service": "api-gateway"]);
    }

    void proxyToCompute(HTTPServerRequest req, HTTPServerResponse res) {
        proxyRequest(req, res, computeServiceUrl);
    }

    void proxyToStorage(HTTPServerRequest req, HTTPServerResponse res) {
        proxyRequest(req, res, storageServiceUrl);
    }

    void proxyToNetwork(HTTPServerRequest req, HTTPServerResponse res) {
        proxyRequest(req, res, networkServiceUrl);
    }

    void proxyToAuth(HTTPServerRequest req, HTTPServerResponse res) {
        proxyRequest(req, res, authServiceUrl);
    }

    void proxyToMonitoring(HTTPServerRequest req, HTTPServerResponse res) {
        proxyRequest(req, res, monitoringServiceUrl);
    }

    void proxyRequest(HTTPServerRequest req, HTTPServerResponse res, string targetUrl) {
        try {
            auto client = requestHTTP(targetUrl ~ req.requestPath,
                (scope clientReq) {
                    clientReq.method = req.method;
                    foreach (key, value; req.headers) {
                        clientReq.headers[key] = value;
                    }
                    if (req.bodyReader.empty) {
                        clientReq.writeBody(cast(ubyte[])req.json.toString());
                    }
                },
                (scope clientRes) {
                    res.statusCode = clientRes.statusCode;
                    foreach (key, value; clientRes.headers) {
                        res.headers[key] = value;
                    }
                    res.bodyWriter.write(clientRes.bodyReader);
                }
            );
        } catch (Exception e) {
            logError("Proxy error: %s", e.msg);
            res.statusCode = HTTPStatus.serviceUnavailable;
            res.writeJsonBody(["error": "Service unavailable", "message": e.msg]);
        }
    }

    void getPlatformStatus(HTTPServerRequest req, HTTPServerResponse res) {
        JSONValue status = [
            "platform": "UIM IaaS",
            "version": "1.0.0",
            "timestamp": Clock.currTime().toISOExtString(),
            "services": [
                "compute": checkServiceHealth(computeServiceUrl),
                "storage": checkServiceHealth(storageServiceUrl),
                "network": checkServiceHealth(networkServiceUrl),
                "auth": checkServiceHealth(authServiceUrl),
                "monitoring": checkServiceHealth(monitoringServiceUrl)
            ]
        ];
        res.writeJsonBody(status);
    }

    bool checkServiceHealth(string serviceUrl) {
        try {
            requestHTTP(serviceUrl ~ "/health",
                (scope req) {},
                (scope res) {
                    return res.statusCode == HTTPStatus.ok;
                }
            );
            return true;
        } catch (Exception) {
            return false;
        }
    }
}

void main() {
    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["0.0.0.0"];
    
    auto router = new URLRouter;
    auto gateway = new ApiGateway();
    gateway.setupRoutes(router);
    
    logInfo("API Gateway starting on port %d", settings.port);
    listenHTTP(settings, router);
    
    runApplication();
}
