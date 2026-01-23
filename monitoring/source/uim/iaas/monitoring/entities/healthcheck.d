/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.monitoring.entities.healthcheck;

import uim.iaas.monitoring;

// Health Check Entity representing health check records in the system
class HealthCheckEntity : IaasEntity {
  this() {
    super();
  }

  protected string _service;
  @property string service() {
    return _service;
  }

  @property void service(string value) {
    _service = value;
  }

  protected string _tenantId;
  @property string tenantId() {
    return _tenantId;
  }

  @property void tenantId(string value) {
    _tenantId = value;
  }

  protected string _status; // healthy, degraded, unhealthy
  @property string status() {
    return _status;
  }

  @property void status(string value) {
    _status = value;
  }

  protected long _responseTime;
  @property long responseTime() {
    return _responseTime;
  }

  @property void responseTime(long value) {
    _responseTime = value;
  }

  protected string _message;
  @property string message() {
    return _message;
  }

  @property void message(string value) {
    _message = value;
  }

  protected long _timestamp;
  @property long timestamp() {
    return _timestamp;
  }

  @property void timestamp(long value) {
    _timestamp = value;
  }

  override Json toJson() {
    return super.toJson().update([
      "service": _service.toJson,
      "tenantId": _tenantId.toJson,
      "status": _status.toJson,
      "responseTime": _responseTime.toJson,
      "message": _message.toJson,
      "timestamp": _timestamp.toJson
    ]);
  }
}
