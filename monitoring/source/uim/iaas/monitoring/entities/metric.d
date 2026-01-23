module uim.iaas.monitoring.entities.metric;

import uim.iaas.monitoring;

// Metric Entity representing monitoring metrics in the system
class MetricEntity : IaasEntity {
  this() {
    super();
  }

  // #region name
  // Name of the metric
  protected string _name;
  @property string name() {
    return _name;
  }

  @property void name(string value) {
    _name = value;
  }
  // #endregion name

  // Tenant ID associated with the metric
  protected string _tenantId;
  @property string tenantId() {
    return _tenantId;
  }

  @property void tenantId(string value) {
    _tenantId = value;
  }

  // Type of the metric
  protected string _type; // gauge, counter, histogram
  @property string type() {
    return _type;
  }

  @property void type(string value) {
    _type = value;
  }

  protected double _value;
  @property double value() {
    return _value;
  }

  @property void value(double newValue) {
    _value = newValue;
  }

  // #region Labels
  // Optional labels for the metric
  protected string[string] _labels;
  @property string[string] labels() {
    return _labels;
  }

  @property void labels(string[string] value) {
    _labels = value;
  }

  @property string labels(string key) {
    return _labels[key];
  }

  @property void labels(string key, string value) {
    _labels[key] = value;
  }
  // #endregion Labels

  // Timestamp of the metric
  protected long _timestamp;
  @property long timestamp() {
    return _timestamp;
  }

  @property void timestamp(long value) {
    _timestamp = value;
  }

  override Json toJson() {
    return super().toJson().update([
      "metadata": _metadata.toJson,
      "name": _name.toJson,
      "tenantId": _tenantId.toJson,
      "type": _type.toJson,
      "value": Json(_value),
      "labels": Json(_labels),
      "timestamp": Json(_timestamp)
    ]);
  }
}
///
unittest {
  import uim.iaas.core.entity : IaasEntity;
  import std.stdio : writeln;

  auto metric = new MetricEntity();
  metric.id = "metric-123";
  metric.createdAt = 1625079600;
  metric.updatedAt = 1625083200;
  metric.metadata = ["env": "production"];
  metric.name = "cpu_usage";
  metric.tenantId = "tenant-456";
  metric.type = "gauge";
  metric.value = 75.5;
  metric.labels = ["host": "server1", "region": "us-west"];
  metric.timestamp = 1625086800;

  auto json = metric.toJson();
  writeln(json);
}
