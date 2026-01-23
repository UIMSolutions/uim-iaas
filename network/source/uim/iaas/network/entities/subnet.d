module uim.iaas.network.entities.subnet;

import uim.iaas.network;

class SubnetEntity : IaasEntity {
    this() {
        super();
    }  
    
    string name;
    string tenantId;
    string networkId;
    string cidr;
    string gateway;
    bool dhcpEnabled;
    string[] dnsServers;
}