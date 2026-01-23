/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
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