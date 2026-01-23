/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.network.entities.securitygroup;

import uim.iaas.network;

class SecurityGroupEntity : IaasEntity {
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

  protected string _description;
  @property string description() {
    return _description;
  }

  @property void description(string value) {
    _description = value;
  }

  protected RuleEntity[] _rules;
  @property RuleEntity[] rules() {
    return _rules;
  }

  @property void rules(RuleEntity[] value) {
    _rules = value;
  }

  void addRule(RuleEntity rule) {
    _rules ~= rule;
  }

  override Json toJson() {
    Json[] rulesList;
    foreach (rule; _rules) {
      rulesList ~= rule.toJson;
    }

    return super.toJson().update([
      "name": _name.toJson,
      "tenantId": _tenantId.toJson,
      "description": _description.toJson,
      "rules": rulesList.toJson
    ]);
  }
