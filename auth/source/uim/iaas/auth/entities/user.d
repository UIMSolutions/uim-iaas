/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
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
