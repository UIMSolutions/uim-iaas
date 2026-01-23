module uim.iaas.network.entities.subnet;

import uim.iaas.network;

class SubnetEntity : IaasEntity {
  this() {
    super();
  }

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

  protected string _networkId;
  @property string networkId() {
    return _networkId;
  }

  @property void networkId(string value) {
    _networkId = value;
  }

  protected string _cidr;
  @property string cidr() {
    return _cidr;
  }

  @property void cidr(string value) {
    _cidr = value;
  }

  protected string _gateway;
  @property string gateway() {
    return _gateway;
  }

  @property void gateway(string value) {
    _gateway = value;
  }

  protected bool _dhcpEnabled;
  @property bool dhcpEnabled() {
    return _dhcpEnabled;
  }

  @property void dhcpEnabled(bool value) {
    _dhcpEnabled = value;
  }

  protected string[] _dnsServers;
  @property string[] dnsServers() {
    return _dnsServers;
  }

  @property void dnsServers(string[] value) {
    _dnsServers = value;
  }

  void addDnsServer(string dns) {
    _dnsServers ~= dns;
  }

  override Json toJson() {
    return super.toJson.update([
      "name": _name.toJson,
      "tenantId": _tenantId.toJson,
      "networkId": _networkId.toJson,
      "cidr": _cidr.toJson,
      "gateway": _gateway.toJson,
      "dhcpEnabled": _dhcpEnabled.toJson,
      "dnsServers": _dnsServers.toJson
    ]);
  }
}