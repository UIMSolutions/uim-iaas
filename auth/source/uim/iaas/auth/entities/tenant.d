module uim.iaas.auth.entities.tenant;

import uim.iaas.auth;

class TenantEntity : UIMEntity {
    string name;
    string description;
    bool active;

    string[string] metadata;
}