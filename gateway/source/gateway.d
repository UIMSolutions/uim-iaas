/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
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
        writeln("Health check requested");
        res.writeJsonBody(["status": "healthy", "service": "api-gateway"]);
    }

    void proxyToCompute(HTTPServerRequest req, HTTPServerResponse res) {
        writeln("Proxying to Compute Service: ", req.requestPath);
        proxyRequest(req, res, computeServiceUrl);
    }

    void proxyToStorage(HTTPServerRequest req, HTTPServerResponse res) {
        writeln("Proxying to Storage Service: ", req.requestPath);
        proxyRequest(req, res, storageServiceUrl);
    }

    void proxyToNetwork(HTTPServerRequest req, HTTPServerResponse res) {
        writeln("Proxying to Network Service: ", req.requestPath);
        proxyRequest(req, res, networkServiceUrl);
    }

    void proxyToAuth(HTTPServerRequest req, HTTPServerResponse res) {
        writeln("Proxying to Auth Service: ", req.requestPath);
        proxyRequest(req, res, authServiceUrl);
    }

    void proxyToMonitoring(HTTPServerRequest req, HTTPServerResponse res) {
        writeln("Proxying to Monitoring Service: ", req.requestPath);
        proxyRequest(req, res, monitoringServiceUrl);
    }

    void proxyRequest(HTTPServerRequest req, HTTPServerResponse res, string targetUrl) {
        writeln("Proxying request to: ", targetUrl, req.requestPath.toString());
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
            
            requestHTTP(targetUrl ~ req.requestPath.toString(),
                (scope HTTPClientRequest clientReq) {
                    clientReq.method = req.method;
                    // Copy headers
                    foreach (k; req.headers.byKeyValue) {
                        clientReq.headers[k.key] = k.value;
                    }
                    // Add tenant ID header for backend services
                    clientReq.headers["X-Tenant-ID"] = tenantId;
                    
                    // Write request body if present
                    if (req.method == HTTPMethod.POST || req.method == HTTPMethod.PUT || req.method == HTTPMethod.PATCH) {
                        try {
                            auto jsonBody = req.json;
                            clientReq.writeJsonBody(jsonBody);
                        } catch (Exception) {
                            // No JSON body
                        }
                    }
                },
                (scope HTTPClientResponse clientRes) {
                    res.statusCode = clientRes.statusCode;
                    // Copy response headers
                    foreach (k; clientRes.headers.byKeyValue) {
                        res.headers[k.key] = k.value;
                    }
                    // Copy response body
                    try {
                        auto jsonBody = clientRes.readJson();
                        res.writeJsonBody(jsonBody);
                    } catch (Exception) {
                        // Not JSON, try raw body
                        try {
                            auto bodyContent = clientRes.bodyReader.readAllUTF8();
                            res.writeBody(bodyContent);
                        } catch (Exception) {
                            // Empty body
                        }
                    }
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
            bool isHealthy = false;
            requestHTTP(serviceUrl ~ "/health",
                (scope req) {},
                (scope res) {
                    isHealthy = res.statusCode == HTTPStatus.ok;
                }
            );
            return isHealthy;
        } catch (Exception) {
            return false;
        }
    }
}