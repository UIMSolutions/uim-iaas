module uim.iaas.storage.entities.bucket;

import uim.iaas.storage;

class BucketEntity : IaasEntity {
    this() {
        super();
    }

    protected string _name;
    @property string name() { return _name; }
    @property void name(string value) { _name = value; }

    protected string _tenantId;
    @property string tenantId() { return _tenantId; }
    @property void tenantId(string value) { _tenantId = value; }

    protected string _region;
    @property string region() { return _region; }
    @property void region(string value) { _region = value; }

    protected long _objectCount;
    @property long objectCount() { return _objectCount; }
    @property void objectCount(long value) { _objectCount = value; }

    protected long _totalSizeBytes;
    @property long totalSizeBytes() { return _totalSizeBytes; }
    @property void totalSizeBytes(long value) { _totalSizeBytes = value; }

    protected string _status;
    @property string status() { return _status; }
    @property void status(string value) { _status = value; }
}
