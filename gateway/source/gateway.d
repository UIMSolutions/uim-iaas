module gateway;

import vibe.vibe;
import std.stdio;
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
            // Extract tenant ID from auth token by calling auth service
            string tenantId = "default";
            auto authHeader = "Authorization" in req.headers;
            
            if (authHeader) {
                // Verify token and get tenant ID
                try {
                    requestHTTP(authServiceUrl ~ "/api/v1/auth/verify",
                        (scope clientReq) {
                            clientReq.method = HTTPMethod.GET;
                            clientReq.headers["Authorization"] = *authHeader;
                        },
                        (scope clientRes) {
                            if (clientRes.statusCode == HTTPStatus.ok) {
                                auto verifyData = clientRes.readJson();
                                if ("tenantId" in verifyData) {
                                    tenantId = verifyData["tenantId"].get!string;
                                }
                            }
                        }
                    );
                } catch (Exception e) {
                    logWarn("Failed to verify token: %s", e.msg);
                }
            }
            
            auto client = requestHTTP(targetUrl ~ req.requestPath),
                (scope clientReq) {
                    clientReq.method = req.method;
                    foreach (key, value; req.headers) {
                        clientReq.headers[key] = value;
                    }
                    // Add tenant ID header for backend services
                    clientReq.headers["X-Tenant-ID"] = tenantId;
                    
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
        Json status = Json([
            "platform": Json("UIM IaaS"),
            "version": Json("2.0.0"),
            "timestamp": Json(Clock.currTime().toISOExtString()),
            "services": Json([
                "compute": Json(checkServiceHealth(computeServiceUrl)),
                "storage": Json(checkServiceHealth(storageServiceUrl)),
                "network": Json(checkServiceHealth(networkServiceUrl)),
                "auth": Json(checkServiceHealth(authServiceUrl)),
                "monitoring": Json(checkServiceHealth(monitoringServiceUrl))
            ])
        ]);
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