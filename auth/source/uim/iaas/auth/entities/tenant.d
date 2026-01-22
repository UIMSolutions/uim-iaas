module uim.iaas.auth.models.tenant;

import uim.iaas.auth;

class TenantEntity : Entity {
    string name;
    string description;
    bool active;

    string[string] metadata;
}