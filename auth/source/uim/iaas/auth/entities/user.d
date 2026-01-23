module uim.iaas.auth.entities.user;

import uim.iaas.auth;

class UserEntity : IaasEntity {
    this () {
        super();
    }

    string username;
    string email;
    string passwordHash;
    string tenantId;
    string role; // admin, user, viewer
    bool active;
    long lastLogin;

    string[string] metadata;


}
