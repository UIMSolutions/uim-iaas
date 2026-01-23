/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.auth.entities.tenant;

import uim.iaas.auth;
@safe:

class TenantEntity : IaasEntity {

  // Getters
  string _name;
  @property string name() {
    return name;
  }

  string _description;
  @property string description() {
    return description;
  }
  @property void description(string value) {
    _description = value;
  }

  // Setters
  @property void name(string value) {
    _name = value;
  }


  bool _active;
  @property bool active() {
    return _active;
  }

  @property void active(bool value) {
    _active = value;
  }

  override Json toJson() {
    return super.toJson().update([
      "name": Json(name),
      "description": Json(description),
      "active": Json(active)
    ]);
  }
}
