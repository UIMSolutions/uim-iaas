module uim.iaas.monitoring.entities.alert;

import uim.iaas.monitoring;

class AlertEntity : UIMEntity {
    this() {
        super();
    }
    
    protected string _name;
    @property string name() { return _name; }
    @property void name(string value) { _name = value; }

    protected string _tenantId;
    @property string tenantId() { return _tenantId; }
    @property void tenantId(string value) { _tenantId = value; }

    protected string _severity; // info, warning, critical
    @property string severity() { return _severity; }
    @property void severity(string value) { _severity = value; }

    protected string _message;
    @property string message() { return _message; }
    @property void message(string value) { _message = value; }

    protected string _source;
    @property string source() { return _source; }
    @property void source(string value) { _source = value; }

    protected bool _active;
    @property bool active() { return _active; }
    @property void active(bool value) { _active = value; }

    protected long _triggeredAt;
    @property long triggeredAt() { return _triggeredAt; }
    @property void triggeredAt(long value) { _triggeredAt = value; }

    protected long _resolvedAt;
    @property long resolvedAt() { return _resolvedAt; }
    @property void resolvedAt(long value) { _resolvedAt = value; }
}