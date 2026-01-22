module uim.iaas.monitoring.entities.metric;

import uim.iaas.monitoring;

class MetricEntity : UIMEntity {
    this() {
        super();
    }

    protected string _name;
    @property string name() { return _name; }
    @property void name(string value) { _name = value; }

    protected string _tenantId;
    @property string tenantId() { return _tenantId; }
    @property void tenantId(string value) { _tenantId = value; }

    protected string _type; // gauge, counter, histogram
    @property string type() { return _type; }
    @property void type(string value) { _type = value; }

    protected double _value;
    @property double value() { return _value; }
    @property void value(double newValue) { _value = newValue; }

    protected string[string] _labels;
    @property string[string] labels() { return _labels; }
    @property void labels(string[string] value) { _labels = value; }

    protected long _timestamp;
    @property long timestamp() { return _timestamp; }
    @property void timestamp(long value) { _timestamp = value; }
}
