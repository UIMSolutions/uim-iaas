module uim.iaas.network.entities.rule;

import uim.iaas.network;

class RuleEntity : IaasEntity {
    this() {
        super();
    }     

    // Properties
    protected string _direction; // ingress, egress
    @property string direction() { return _direction; }
    @property void direction(string value) { _direction = value; }

    protected string _protocol; // tcp, udp, icmp
    @property string protocol() { return _protocol; }
    @property void protocol(string value) { _protocol = value; }

    protected int _portMin;
    @property int portMin() { return _portMin; }
    @property void portMin(int value) { _portMin = value; }

    protected int _portMax;
    @property int portMax() { return _portMax; }
    @property void portMax(int value) { _portMax = value; }

    protected string _cidr;
    @property string cidr() { return _cidr; }
    @property void cidr(string value) { _cidr = value; }
}