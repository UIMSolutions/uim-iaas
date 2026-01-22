module uim.iaas.network.entities.network;

import uim.iaas.network;

class NetworkEntity : UIMEntity {
    this() {
        super();
    }   

    // Properties
    protected string _name;
    @property string name() { return _name; }
    @property void name(string value) { _name = value; }

    protected string _tenantId;
    @property string tenantId() { return _tenantId; }
    @property void tenantId(string value) { _tenantId = value; }

    protected string _cidr;
    @property string cidr() { return _cidr; }
    @property void cidr(string value) { _cidr = value; }

    protected string _status;
    @property string status() { return _status; }
    @property void status(string value) { _status = value; }
}