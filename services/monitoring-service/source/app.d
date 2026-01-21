module app;

import vibe.vibe;
import std.stdio;
import std.datetime;
import std.algorithm;
import std.array;

/**
 * Monitoring Service - Collects and provides metrics and health data with multi-tenancy
 */

struct Metric {
    string name;
    string tenantId;
    string type; // gauge, counter, histogram
    double value;
    string[string] labels;
    long timestamp;
}

struct Alert {
    string id;
    string name;
    string tenantId;
    string severity; // info, warning, critical
    string message;
    string source;
    bool active;
    long triggeredAt;
    long resolvedAt;
}

struct HealthCheck {
    string service;
    string tenantId;
    string status; // healthy, degraded, unhealthy
    long responseTime;
    string message;
    long timestamp;
}

class MonitoringService {
    private Metric[] metrics;
    private Alert[string] alerts;
    private HealthCheck[string] healthChecks;

    void setupRoutes(URLRouter router) {
        router.get("/health", &healthCheck);
        
        // Metrics
        router.get("/api/v1/monitoring/metrics", &getMetrics);
        router.post("/api/v1/monitoring/metrics", &recordMetric);
        router.get("/api/v1/monitoring/metrics/:name", &getMetricsByName);
        
        // Alerts
        router.get("/api/v1/monitoring/alerts", &listAlerts);
        router.get("/api/v1/monitoring/alerts/:id", &getAlert);
        router.post("/api/v1/monitoring/alerts", &createAlert);
        router.post("/api/v1/monitoring/alerts/:id/resolve", &resolveAlert);
        
        // Health checks
        router.get("/api/v1/monitoring/health-checks", &listHealthChecks);
        router.post("/api/v1/monitoring/health-checks", &recordHealthCheck);
        router.get("/api/v1/monitoring/dashboard", &getDashboard);
    }

    void healthCheck(HTTPServerRequest req, HTTPServerResponse res) {
        res.writeJsonBody(["status": "healthy", "service": "monitoring-service"]);
    }

    void getMetrics(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        // Filter by time range if provided
        long startTime = 0;
        long endTime = Clock.currTime().toUnixTime();
        
        if ("start" in req.query) {
            import std.conv : to;
            startTime = req.query["start"].to!long;
        }
        if ("end" in req.query) {
            import std.conv : to;
            endTime = req.query["end"].to!long;
        }
        
        auto filtered = metrics.filter!(m => 
            m.tenantId == tenantId && 
            m.timestamp >= startTime && 
            m.timestamp <= endTime
        );
        
        Json[] metricList;
        foreach (metric; filtered) {
            metricList ~= serializeMetric(metric);
        }
        
        res.writeJsonBody(["metrics": Json(metricList), "count": Json(metricList.length)]);
    }

    void recordMetric(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        auto metric = Metric();
        metric.name = data["name"].get!string;
        metric.tenantId = tenantId;
        metric.type = ("type" in data) ? data["type"].get!string : "gauge";
        metric.value = data["value"].get!double;
        metric.timestamp = Clock.currTime().toUnixTime();
        
        if ("labels" in data) {
            foreach (string key, ref value; data["labels"].byKeyValue) {
                metric.labels[key] = value.get!string;
            }
        }
        
        metrics ~= metric;
        
        // Keep only last 10000 metrics
        if (metrics.length > 10000) {
            metrics = metrics[$-10000..$];
        }
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeMetric(metric));
    }

    void getMetricsByName(HTTPServerRequest req, HTTPServerResponse res) {
        auto name = req.params["name"];
        auto tenantId = getTenantIdFromRequest(req);
        
        auto filtered = metrics.filter!(m => m.name == name && m.tenantId == tenantId);
        
        Json[] metricList;
        foreach (metric; filtered) {
            metricList ~= serializeMetric(metric);
        }
        
        // Calculate aggregations
        if (metricList.length > 0) {
            double sum = 0;
            double min = double.max;
            double max = double.min_normal;
            
            foreach (m; filtered) {
                sum += m.value;
                if (m.value < min) min = m.value;
                if (m.value > max) max = m.value;
            }
            
            auto avg = sum / metricList.length;
            
            res.writeJsonBody([
                "name": Json(name),
                "metrics": Json(metricList),
                "count": Json(metricList.length),
                "aggregations": Json([
                    "min": Json(min),
                    "max": Json(max),
                    "avg": Json(avg),
                    "sum": Json(sum)
                ])
            ]);
        } else {
            res.writeJsonBody(["name": Json(name), "metrics": Json(metricList), "count": Json(0)]);
        }
    }

    void listAlerts(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        bool activeOnly = false;
        if ("active" in req.query && req.query["active"] == "true") {
            activeOnly = true;
        }
        
        JSONValue[] alertList;
        foreach (alert; alerts) {
            if (alert.tenantId == tenantId && (!activeOnly || alert.active)) {
                alertList ~= serializeAlert(alert);
            }
        }
        
        res.writeJsonBody(["alerts": JSONValue(alertList)]);
    }

    void getAlert(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in alerts) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": JSONValue("Alert not found")]);
            return;
        }
        
        res.writeJsonBody(serializeAlert(alerts[id]));
    }

    void createAlert(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        import std.uuid;
        auto alert = Alert();
        alert.id = randomUUID().toString();
        alert.name = data["name"].get!string;
        alert.tenantId = tenantId;
        alert.severity = ("severity" in data) ? data["severity"].get!string : "warning";
        alert.message = data["message"].get!string;
        alert.source = ("source" in data) ? data["source"].get!string : "unknown";
        alert.active = true;
        alert.triggeredAt = Clock.currTime().toUnixTime();
        alert.resolvedAt = 0;
        
        alerts[alert.id] = alert;
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeAlert(alert));
    }

    void resolveAlert(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in alerts) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Alert not found"]);
            return;
        }
        
        alerts[id].active = false;
        alerts[id].resolvedAt = Clock.currTime().toUnixTime();
        
        res.writeJsonBody(serializeAlert(alerts[id]));
    }

    void listHealthChecks(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        JSONValue[] healthList;
        foreach (health; healthChecks) {
            if (health.tenantId == tenantId) {
                healthList ~= serializeHealthCheck(health);
            }
        }
        
        res.writeJsonBody(["healthChecks": JSONValue(healthList)]);
    }

    void recordHealthCheck(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        auto health = HealthCheck();
        health.service = data["service"].get!string;
        health.tenantId = tenantId;
        health.status = data["status"].get!string;
        health.responseTime = ("responseTime" in data) ? data["responseTime"].get!long : 0;
        health.message = ("message" in data) ? data["message"].get!string : "";
        health.timestamp = Clock.currTime().toUnixTime();
        
        healthChecks[health.service] = health;
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeHealthCheck(health));
    }

    void getDashboard(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        // Get active alerts for this tenant
        int criticalCount = 0;
        int warningCount = 0;
        int infoCount = 0;
        
        foreach (alert; alerts) {
            if (alert.tenantId == tenantId && alert.active) {
                switch (alert.severity) {
                    case "critical": criticalCount++; break;
                    case "warning": warningCount++; break;
                    case "info": infoCount++; break;
                    default: break;
                }
            }
        }
        
        // Get service health summary for this tenant
        int healthyCount = 0;
        int degradedCount = 0;
        int unhealthyCount = 0;
        
        foreach (health; healthChecks) {
            if (health.tenantId == tenantId) {
                switch (health.status) {
                    case "healthy": healthyCount++; break;
                    case "degraded": degradedCount++; break;
                    case "unhealthy": unhealthyCount++; break;
                    default: break;
                }
            }
        }
        
        // Get recent metrics count for this tenant
        auto recentTime = Clock.currTime().toUnixTime() - 3600; // Last hour
        auto recentMetrics = metrics.filter!(m => m.tenantId == tenantId && m.timestamp >= recentTime).array.length;
        
        res.writeJsonBody([
            "dashboard": JSONValue([
                "timestamp": JSONValue(Clock.currTime().toUnixTime()),
                "alerts": JSONValue([
                    "critical": JSONValue(criticalCount),
                    "warning": JSONValue(warningCount),
                    "info": JSONValue(infoCount),
                    "total": JSONValue(criticalCount + warningCount + infoCount)
                ]),
                "services": JSONValue([
                    "healthy": JSONValue(healthyCount),
                    "degraded": JSONValue(degradedCount),
                    "unhealthy": JSONValue(unhealthyCount),
                    "total": JSONValue(healthyCount + degradedCount + unhealthyCount)
                ]),
                "metrics": JSONValue([
                    "total": JSONValue(metrics.length),
                    "lastHour": JSONValue(recentMetrics)
                ])
            ])
        ]);
    }

    string getTenantIdFromRequest(HTTPServerRequest req) {
        if ("X-Tenant-ID" in req.headers) {
            return req.headers["X-Tenant-ID"];
        }
        return "default";
    }

    JSONValue serializeMetric(Metric metric) {
        JSONValue labels = JSONValue.emptyObject;
        foreach (key, value; metric.labels) {
            labels[key] = JSONValue(value);
        }
        
        return JSONValue([
            "name": JSONValue(metric.name),
            "tenantId": JSONValue(metric.tenantId),
            "type": JSONValue(metric.type),
            "value": JSONValue(metric.value),
            "labels": labels,
            "timestamp": JSONValue(metric.timestamp)
        ]);
    }

    JSONValue serializeAlert(Alert alert) {
        return JSONValue([
            "id": JSONValue(alert.id),
            "name": JSONValue(alert.name),
            "tenantId": JSONValue(alert.tenantId),
            "severity": JSONValue(alert.severity),
            "message": JSONValue(alert.message),
            "source": JSONValue(alert.source),
            "active": JSONValue(alert.active),
            "triggeredAt": JSONValue(alert.triggeredAt),
            "resolvedAt": JSONValue(alert.resolvedAt)
        ]);
    }

    JSONValue serializeHealthCheck(HealthCheck health) {
        return JSONValue([
            "service": JSONValue(health.service),
            "tenantId": JSONValue(health.tenantId),
            "status": JSONValue(health.status),
            "responseTime": JSONValue(health.responseTime),
            "message": JSONValue(health.message),
            "timestamp": JSONValue(health.timestamp)
        ]);
    }
}

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
