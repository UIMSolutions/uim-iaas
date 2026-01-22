module uim.iaas.network.entities.securitygroup;

import uim.iaas.network;

class SecurityGroupEntity : UIMEntity {
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

    protected string _description;
    @property string description() { return _description; }
    @property void description(string value) { _description = value; }

    protected RuleEntity[] _rules;
    @property RuleEntity[] rules() { return _rules; }
    @property void rules(RuleEntity[] value) { _rules = value; }
}