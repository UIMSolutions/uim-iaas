module uim.iaas.auth.models.session;

import uim.iaas.auth;

class SessionEntity : Entity {
    this () {
        super();
    }

    string userId;
    string tenantId;
    string token;
    long expiresAt;
}