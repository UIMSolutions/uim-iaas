module uim.iaas.auth.models.user;

import uim.iaas.auth;

class UserEntity : Entity {
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
