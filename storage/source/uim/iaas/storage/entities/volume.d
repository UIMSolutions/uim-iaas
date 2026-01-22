module uim.iaas.storage.entities.volume;

import uim.iaas.storage;

class VolumeEntity : UIMEntity {
    this() {
        super();
    }

    protected string _name;
    @property string name() { return _name; }
    @property void name(string value) { _name = value; }

    protected string _tenantId;
    @property string tenantId() { return _tenantId; }
    @property void tenantId(string value) { _tenantId = value; }

    protected string _type; // block, object
    @property string type() { return _type; }
    @property void type(string value) { _type = value; }

    protected long _sizeGB;
    @property long sizeGB() { return _sizeGB; }
    @property void sizeGB(long value) { _sizeGB = value; }

    protected string _status; // available, in-use, creating, deleting, error
    @property string status() { return _status; }
    @property void status(string value) { _status = value; }

    protected string _attachedTo; // instance ID
    @property string attachedTo() { return _attachedTo; }
    @property void attachedTo(string value) { _attachedTo = value; }
}