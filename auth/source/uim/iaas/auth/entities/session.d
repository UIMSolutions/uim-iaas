module uim.iaas.auth.entities.session;

import uim.iaas.auth;

class SessionEntity : IaasEntity {
    this () {
        super();
    }

    string userId;
    string tenantId;
    string token;
    long expiresAt;
}