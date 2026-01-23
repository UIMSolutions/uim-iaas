/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.auth.entities.user;

import uim.iaas.auth;
@safe:

class UserEntity : IaasEntity {
  this() {
    super();
  }

  string _username;
  string _email;
  string _passwordHash;
  string _tenantId;
  string _role; // admin, user, viewer
  bool _active;
  long _lastLogin;

  // Getters
  string username() {
    return _username;
  }

  string email() {
    return _email;
  }

  string passwordHash() {
    return _passwordHash;
  }

  string tenantId() {
    return _tenantId;
  }

  string role() {
    return _role;
  }

  bool active() {
    return _active;
  }

  long lastLogin() {
    return _lastLogin;
  }

  // Setters
  void username(string value) {
    _username = value;
  }

  void email(string value) {
    _email = value;
  }

  void passwordHash(string value) {
    _passwordHash = value;
  }

  void tenantId(string value) {
    _tenantId = value;
  }

  void role(string value) {
    _role = value;
  }

  void active(bool value) {
    _active = value;
  }

  void lastLogin(long value) {
    _lastLogin = value;
  }

  override Json toJson() {
    return super.toJson().update([
      "username": Json(username),
      "email": Json(email),
      "tenantId": Json(tenantId),
      "role": Json(role),
      "active": Json(active),
      "lastLogin": Json(lastLogin)
    ]);
  }
}
