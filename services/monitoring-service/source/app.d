module app;

import vibe.vibe;
import std.stdio;
import std.json;
import std.datetime;
import std.algorithm;
import std.array;

/**
 * Monitoring Service - Collects and provides metrics and health data
 */

struct Metric {
    string name;
    string type; // gauge, counter, histogram
    double value;
    string[string] labels;
    long timestamp;
}

struct Alert {
    string id;
    string name;
    string severity; // info, warning, critical
    string message;
    string source;
    bool active;
    long triggeredAt;
    long resolvedAt;
}

struct HealthCheck {
    string service;
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
        
        auto filtered = metrics.filter!(m => m.timestamp >= startTime && m.timestamp <= endTime);
        
        JSONValue[] metricList;
        foreach (metric; filtered) {
            metricList ~= serializeMetric(metric);
        }
        
        res.writeJsonBody(["metrics": metricList, "count": metricList.length]);
    }

    void recordMetric(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        
        auto metric = Metric();
        metric.name = data["name"].str;
        metric.type = data.get("type", JSONValue("gauge")).str;
        metric.value = data["value"].floating;
        metric.timestamp = Clock.currTime().toUnixTime();
        
        if ("labels" in data) {
            foreach (string key, value; data["labels"].object) {
                metric.labels[key] = value.str;
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
        
        auto filtered = metrics.filter!(m => m.name == name);
        
        JSONValue[] metricList;
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
                "name": name,
                "metrics": metricList,
                "count": metricList.length,
                "aggregations": [
                    "min": min,
                    "max": max,
                    "avg": avg,
                    "sum": sum
                ]
            ]);
        } else {
            res.writeJsonBody(["name": name, "metrics": metricList, "count": 0]);
        }
    }

    void listAlerts(HTTPServerRequest req, HTTPServerResponse res) {
        bool activeOnly = false;
        if ("active" in req.query && req.query["active"] == "true") {
            activeOnly = true;
        }
        
        JSONValue[] alertList;
        foreach (alert; alerts) {
            if (!activeOnly || alert.active) {
                alertList ~= serializeAlert(alert);
            }
        }
        
        res.writeJsonBody(["alerts": alertList]);
    }

    void getAlert(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in alerts) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Alert not found"]);
            return;
        }
        
        res.writeJsonBody(serializeAlert(alerts[id]));
    }

    void createAlert(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        
        import std.uuid;
        auto alert = Alert();
        alert.id = randomUUID().toString();
        alert.name = data["name"].str;
        alert.severity = data.get("severity", JSONValue("warning")).str;
        alert.message = data["message"].str;
        alert.source = data.get("source", JSONValue("unknown")).str;
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
        JSONValue[] healthList;
        foreach (health; healthChecks) {
            healthList ~= serializeHealthCheck(health);
        }
        
        res.writeJsonBody(["healthChecks": healthList]);
    }

    void recordHealthCheck(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        
        auto health = HealthCheck();
        health.service = data["service"].str;
        health.status = data["status"].str;
        health.responseTime = data.get("responseTime", JSONValue(0)).integer;
        health.message = data.get("message", JSONValue("")).str;
        health.timestamp = Clock.currTime().toUnixTime();
        
        healthChecks[health.service] = health;
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeHealthCheck(health));
    }

    void getDashboard(HTTPServerRequest req, HTTPServerResponse res) {
        // Get active alerts
        int criticalCount = 0;
        int warningCount = 0;
        int infoCount = 0;
        
        foreach (alert; alerts) {
            if (alert.active) {
                switch (alert.severity) {
                    case "critical": criticalCount++; break;
                    case "warning": warningCount++; break;
                    case "info": infoCount++; break;
                    default: break;
                }
            }
        }
        
        // Get service health summary
        int healthyCount = 0;
        int degradedCount = 0;
        int unhealthyCount = 0;
        
        foreach (health; healthChecks) {
            switch (health.status) {
                case "healthy": healthyCount++; break;
                case "degraded": degradedCount++; break;
                case "unhealthy": unhealthyCount++; break;
                default: break;
            }
        }
        
        // Get recent metrics count
        auto recentTime = Clock.currTime().toUnixTime() - 3600; // Last hour
        auto recentMetrics = metrics.filter!(m => m.timestamp >= recentTime).array.length;
        
        res.writeJsonBody([
            "dashboard": [
                "timestamp": Clock.currTime().toUnixTime(),
                "alerts": [
                    "critical": criticalCount,
                    "warning": warningCount,
                    "info": infoCount,
                    "total": criticalCount + warningCount + infoCount
                ],
                "services": [
                    "healthy": healthyCount,
                    "degraded": degradedCount,
                    "unhealthy": unhealthyCount,
                    "total": healthyCount + degradedCount + unhealthyCount
                ],
                "metrics": [
                    "total": metrics.length,
                    "lastHour": recentMetrics
                ]
            ]
        ]);
    }

    JSONValue serializeMetric(Metric metric) {
        JSONValue labels = JSONValue.emptyObject;
        foreach (key, value; metric.labels) {
            labels[key] = value;
        }
        
        return JSONValue([
            "name": metric.name,
            "type": metric.type,
            "value": metric.value,
            "labels": labels,
            "timestamp": metric.timestamp
        ]);
    }

    JSONValue serializeAlert(Alert alert) {
        return JSONValue([
            "id": alert.id,
            "name": alert.name,
            "severity": alert.severity,
            "message": alert.message,
            "source": alert.source,
            "active": alert.active,
            "triggeredAt": alert.triggeredAt,
            "resolvedAt": alert.resolvedAt
        ]);
    }

    JSONValue serializeHealthCheck(HealthCheck health) {
        return JSONValue([
            "service": health.service,
            "status": health.status,
            "responseTime": health.responseTime,
            "message": health.message,
            "timestamp": health.timestamp
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
