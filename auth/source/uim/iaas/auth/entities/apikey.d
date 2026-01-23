module uim.iaas.auth.entities.apikey;

import uim.iaas.auth;

class ApiKeyEntity : IaasEntity {
    this () {
        super();
    }

    string key;
    string userId;
    string name;
    string[] scopes;
    bool active;
    long expiresAt;
}