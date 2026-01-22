module uim.iaas.auth.models.apikey;

import uim.iaas.auth;

class ApiKeyEntity : Entity {
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