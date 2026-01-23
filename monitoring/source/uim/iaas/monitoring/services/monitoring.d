/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.monitoring.services.monitoring;

import uim.iaas.monitoring;

/**
 * Monitoring Service - Collects and provides metrics and health data with multi-tenancy
 */
class MonitoringService {
    private MetricEntity[] metrics;
    private AlertEntity[string] alerts;
    private HealthCheckEntity[string] healthChecks;

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
            metricList ~= metric.toJson;
        }

        res.writeJsonBody([
            "metrics": Json(metricList),
            "count": Json(metricList.length)
        ]);
    }

    void recordMetric(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);

        auto metric = new MetricEntity();
        metric.name = data["name"].get!string;
        metric.tenantId = tenantId;
        metric.type = ("type" in data) ? data["type"].get!string : "gauge";
        metric.value = data["value"].get!double;
        metric.timestamp = Clock.currTime().toUnixTime();

        if ("labels" in data) {
            foreach (string key, ref value; data["labels"].byKeyValue) {
                metric.labels(key, value.get!string);
            }
        }

        metrics ~= metric;

        // Keep only last 10000 metrics
        if (metrics.length > 10000) {
            metrics = metrics[$ - 10000 .. $];
        }

        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(metric.toJson);
    }

    void getMetricsByName(HTTPServerRequest req, HTTPServerResponse res) {
        auto name = req.params["name"];
        auto tenantId = getTenantIdFromRequest(req);

        auto filtered = metrics.filter!(m => m.name == name && m.tenantId == tenantId);

        Json[] metricList;
        foreach (metric; filtered) {
            metricList ~= metric.toJson;
        }

        // Calculate aggregations
        if (metricList.length > 0) {
            double sum = 0;
            double min = double.max;
            double max = double.min_normal;

            foreach (m; filtered) {
                sum += m.value;
                if (m.value < min)
                    min = m.value;
                if (m.value > max)
                    max = m.value;
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
            res.writeJsonBody([
                "name": Json(name),
                "metrics": Json(metricList),
                "count": Json(0)
            ]);
        }
    }

    void listAlerts(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        bool activeOnly = false;
        if ("active" in req.query && req.query["active"] == "true") {
            activeOnly = true;
        }

        Json[] alertList;
        foreach (alert; alerts) {
            if (alert.tenantId == tenantId && (!activeOnly || alert.active)) {
                alertList ~= alert.toJson;
            }
        }

        res.writeJsonBody(["alerts": Json(alertList)]);
    }

    void getAlert(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in alerts) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": Json("Alert not found")]);
            return;
        }

        res.writeJsonBody(alerts[id].toJson);
    }

    void createAlert(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);

        import std.uuid;

        auto alert = new AlertEntity();
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
        res.writeJsonBody(alert.toJson);
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

        res.writeJsonBody(alerts[id].toJson);
    }

    void listHealthChecks(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);

        Json[] healthList;
        foreach (health; healthChecks) {
            if (health.tenantId == tenantId) {
                healthList ~= health.toJson;
            }
        }

        res.writeJsonBody(["healthChecks": Json(healthList)]);
    }

    void recordHealthCheck(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);

        auto health = new HealthCheckEntity();
        health.service = data["service"].get!string;
        health.tenantId = tenantId;
        health.status = data["status"].get!string;
        health.responseTime = ("responseTime" in data) ? data["responseTime"].get!long : 0;
        health.message = ("message" in data) ? data["message"].get!string : "";
        health.timestamp = Clock.currTime().toUnixTime();

        healthChecks[health.service] = health;

        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(health.toJson);
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
                case "critical":
                    criticalCount++;
                    break;
                case "warning":
                    warningCount++;
                    break;
                case "info":
                    infoCount++;
                    break;
                default:
                    break;
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
                case "healthy":
                    healthyCount++;
                    break;
                case "degraded":
                    degradedCount++;
                    break;
                case "unhealthy":
                    unhealthyCount++;
                    break;
                default:
                    break;
                }
            }
        }

        // Get recent metrics count for this tenant
        auto recentTime = Clock.currTime().toUnixTime() - 3600; // Last hour
        auto recentMetrics = metrics.filter!(m => m.tenantId == tenantId && m.timestamp >= recentTime)
            .array.length;

        res.writeJsonBody([
            "dashboard": Json([
                "timestamp": Json(Clock.currTime().toUnixTime()),
                "alerts": Json([
                    "critical": Json(criticalCount),
                    "warning": Json(warningCount),
                    "info": Json(infoCount),
                    "total": Json(criticalCount + warningCount + infoCount)
                ]),
                "services": Json([
                    "healthy": Json(healthyCount),
                    "degraded": Json(degradedCount),
                    "unhealthy": Json(unhealthyCount),
                    "total": Json(healthyCount + degradedCount + unhealthyCount)
                ]),
                "metrics": Json([
                    "total": Json(metrics.length),
                    "lastHour": Json(recentMetrics)
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

}
