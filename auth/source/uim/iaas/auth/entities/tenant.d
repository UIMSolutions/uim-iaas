module uim.iaas.auth.entities.tenant;

import uim.iaas.auth;

class TenantEntity : IaasEntity {
    string name;
    string description;
    bool active;

    string[string] metadata;
}