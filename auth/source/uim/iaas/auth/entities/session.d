/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
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