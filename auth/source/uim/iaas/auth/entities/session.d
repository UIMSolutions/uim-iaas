/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.auth.entities.session;

import uim.iaas.auth;
@safe:

class SessionEntity : IaasEntity {
  this() {
    super();
  }

  // Getters
  protected string _userId;
  @property string userId() {
    return _userId;
  }
  // Setters
  @property void userId(string value) {
    _userId = value;
  }

  protected string _tenantId;
  @property string tenantId() {
    return _tenantId;
  }

  @property void tenantId(string value) {
    _tenantId = value;
  }

  protected string _token;
  @property string token() {
    return _token;
  }

  @property void token(string value) {
    _token = value;
  }

  protected long _expiresAt;
  @property long expiresAt() {
    return _expiresAt;
  }

  @property void expiresAt(long value) {
    _expiresAt = value;
  }

  override Json toJson() {
    return super.toJson().update(
      [
      "userId": Json(userId),
      "tenantId": Json(tenantId),
      "token": Json(token),
      "expiresAt": Json(expiresAt)
    ]);
  }
}
