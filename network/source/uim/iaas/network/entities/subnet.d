module uim.iaas.network.entities.subnet;

import uim.iaas.network;

class SubnetEntity : UIMEntity {
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