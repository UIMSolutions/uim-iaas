/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.network.entities.network;

import uim.iaas.network;

// Network Entity representing network resources in the system
class NetworkEntity : IaasEntity {
  this() {
    super();
  }

  // Properties
  protected string _name;
  @property string name() {
    return _name;
  }

  @property void name(string value) {
    _name = value;
  }

  protected string _tenantId;
  @property string tenantId() {
    return _tenantId;
  }

  @property void tenantId(string value) {
    _tenantId = value;
  }

  protected string _cidr;
  @property string cidr() {
    return _cidr;
  }

  @property void cidr(string value) {
    _cidr = value;
  }

  protected string _status;
  @property string status() {
    return _status;
  }

  @property void status(string value) {
    _status = value;
  }

  Json toJson() {
    return super.toJson.update([
      "name": _name.toJson,
      "tenantId": _tenantId.toJson,
      "cidr": _cidr.toJson,
      "status": _status.toJson
    ]);
  }
}
