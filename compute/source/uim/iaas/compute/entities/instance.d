module uim.iaas.compute.entities.instance;

import uim.iaas.compute;

class InstanceEntity : IaasEntity{
    this() {
        super();
    }

    // Getters and Setters
    protected string _id;
    @property string id() { return _id; }
    @property void id(string value) { _id = value; }

    // Name of the instance
    protected string _name;
    @property string name() { return _name; }
    @property void name(string value) { _name = value; }

    // Tenant ID owning the instance
    protected string _tenantId;
    @property string tenantId() { return _tenantId; }
    @property void tenantId(string value) { _tenantId = value; }

    // Type of the instance
    protected string _type; // vm, container
    @property string type() { return _type; }
    @property void type(string value) { _type = value; }

    // Flavor of the instance
    protected string _flavor; // small, medium, large
    @property string flavor() { return _flavor; }
    @property void flavor(string value) { _flavor = value; }

    // Current status of the instance
    protected string _status; // creating, running, stopped, error
    @property string status() { return _status; }
    @property void status(string value) { _status = value; }

    // ID of the image used to create the instance
    protected string _imageId;
    @property string imageId() { return _imageId; }
    @property void imageId(string value) { _imageId = value; }

    // Lists of associated network and volume IDs
    protected string[] _networkIds;
    @property string[] networkIds() { return _networkIds; }
    @property void networkIds(string[] value) { _networkIds = value; }

    void addNetworkId(string netId) {
        _networkIds ~= netId;
    }

    // Lists of associated volume IDs
    protected string[] _volumeIds;
    @property string[] volumeIds() { return _volumeIds; }
    @property void volumeIds(string[] value) { _volumeIds = value; }

    void addVolumeId(string volId) {
        _volumeIds ~= volId;
    }
    
    // Timestamps
    protected long _createdAt;
    @property long createdAt() { return _createdAt; }
    @property void createdAt(long value) { _createdAt = value; }

    // Updated timestamp
    protected long _updatedAt;
    @property long updatedAt() { return _updatedAt; }
    @property void updatedAt(long value) { _updatedAt = value; }

    // Metadata key-value pairs
    protected string[string] _metadata;
    @property string[string] metadata() { return _metadata; }
    @property void metadata(string[string] value) { _metadata = value; }

    @property string metadata(string key) { return _metadata[key]; }
    @property void metadata(string key, string value) { _metadata[key] = value; }
}