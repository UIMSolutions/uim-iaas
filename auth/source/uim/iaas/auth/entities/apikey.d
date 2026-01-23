/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.auth.entities.apikey;

import uim.iaas.auth;

@safe:

class ApiKeyEntity : IaasEntity {
  this() {
    super();
  }

  protected bool _active;
  protected long _expiresAt;

  // Getters
  protected string _key;
  @property string key() {
    return _key;
  }

  protected string _userId;
  @property string userId() {
    return _userId;
  }

  protected string _name;
  @property string name() {
    return _name;
  }

  protected string[] _scopes;
  @property string[] scopes() {
    return _scopes;
  }

  @property void scopes(string[] value) {
    _scopes = value;
  }

  void addScopes(string value) {
    _scopes ~= value;
  }

  @property bool active() {
    return _active;
  }

  @property long expiresAt() {
    return _expiresAt;
  }

  // Setters
  @property void key(string value) {
    _key = value;
  }

  @property void userId(string value) {
    _userId = value;
  }

  @property void name(string value) {
    _name = value;
  }

  @property void active(bool value) {
    _active = value;
  }

  @property void expiresAt(long value) {
    _expiresAt = value;
  }

  override Json toJson() {
    return super.toJson().update(
      [
      "key": key.toJson(),
      "userId": userId.toJson(),
      "name": name.toJson(),
      "scopes": scopes.toJson(),
      "active": active.toJson(),
    ]);
  }
}
