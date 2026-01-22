module app;

import vibe.vibe;
import std.stdio;
import std.uuid;
import std.datetime;

/**
 * Network Service - Manages virtual networks, subnets, and security groups with multi-tenancy
 */

struct Network {
    string id;
    string name;
    string tenantId;
    string cidr;
    string status;
    long createdAt;
    long updatedAt;
    string[string] metadata;
}

struct Subnet {
    string id;
    string name;
    string tenantId;
    string networkId;
    string cidr;
    string gateway;
    bool dhcpEnabled;
    string[] dnsServers;
    long createdAt;
    string[string] metadata;
}

struct SecurityGroup {
    string id;
    string name;
    string tenantId;
    string description;
    Rule[] rules;
    long createdAt;
    long updatedAt;
}

struct Rule {
    string id;
    string direction; // ingress, egress
    string protocol; // tcp, udp, icmp
    int portMin;
    int portMax;
    string cidr;
}

class NetworkService {
    private Network[string] networks;
    private Subnet[string] subnets;
    private SecurityGroup[string] securityGroups;

    void setupRoutes(URLRouter router) {
        router.get("/health", &healthCheck);
        
        // Network management
        router.get("/api/v1/network/networks", &listNetworks);
        router.get("/api/v1/network/networks/:id", &getNetwork);
        router.post("/api/v1/network/networks", &createNetwork);
        router.delete_("/api/v1/network/networks/:id", &deleteNetwork);
        
        // Subnet management
        router.get("/api/v1/network/subnets", &listSubnets);
        router.get("/api/v1/network/subnets/:id", &getSubnet);
        router.post("/api/v1/network/subnets", &createSubnet);
        router.delete_("/api/v1/network/subnets/:id", &deleteSubnet);
        
        // Security group management
        router.get("/api/v1/network/security-groups", &listSecurityGroups);
        router.get("/api/v1/network/security-groups/:id", &getSecurityGroup);
        router.post("/api/v1/network/security-groups", &createSecurityGroup);
        router.delete_("/api/v1/network/security-groups/:id", &deleteSecurityGroup);
        router.post("/api/v1/network/security-groups/:id/rules", &addSecurityRule);
        router.delete_("/api/v1/network/security-groups/:id/rules/:ruleId", &removeSecurityRule);
    }

    void healthCheck(HTTPServerRequest req, HTTPServerResponse res) {
        res.writeJsonBody(["status": "healthy", "service": "network-service"]);
    }

    // Network operations
    void listNetworks(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        JSONValue[] networkList;
        foreach (network; networks) {
            if (network.tenantId == tenantId) {
                networkList ~= serializeNetwork(network);
            }
        }
        res.writeJsonBody(["networks": networkList]);
    }

    void getNetwork(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in networks) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Network not found"]);
            return;
        }
        res.writeJsonBody(serializeNetwork(networks[id]));
    }

    void createNetwork(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        auto network = Network();
        network.id = randomUUID().toString();
        network.name = data["name"].get!string;
        network.tenantId = tenantId;
        network.cidr = data["cidr"].get!string;
        network.status = "active";
        network.createdAt = Clock.currTime().toUnixTime();
        network.updatedAt = network.createdAt;
        
        if ("metadata" in data && data["metadata"].type == Json.Type.object) {
            foreach (string key, value; data["metadata"].byKeyValue) {
                network.metadata[key] = value.get!string;
            }
        }
        
        networks[network.id] = network;
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeNetwork(network));
    }

    void deleteNetwork(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in networks) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Network not found"]);
            return;
        }
        
        // Check if network has subnets
        foreach (subnet; subnets) {
            if (subnet.networkId == id) {
                res.statusCode = HTTPStatus.badRequest;
                res.writeJsonBody(["error": "Network has active subnets"]);
                return;
            }
        }
        
        networks.remove(id);
        res.statusCode = HTTPStatus.noContent;
        res.writeVoidBody();
    }

    // Subnet operations
    void listSubnets(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        Json[] subnetList;
        foreach (subnet; subnets) {
            if (subnet.tenantId == tenantId) {
                subnetList ~= serializeSubnet(subnet);
            }
        }
        res.writeJsonBody(Json(["subnets": Json(subnetList)]));
    }

    void getSubnet(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in subnets) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Subnet not found"]);
            return;
        }
        res.writeJsonBody(serializeSubnet(subnets[id]));
    }

    void createSubnet(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        auto subnet = Subnet();
        subnet.id = randomUUID().toString();
        subnet.name = data["name"].get!string;
        subnet.tenantId = tenantId;
        subnet.networkId = data["networkId"].get!string;
        subnet.cidr = data["cidr"].get!string;
        subnet.gateway = data["gateway"].get!string;
        subnet.dhcpEnabled = ("dhcpEnabled" in data) ? data["dhcpEnabled"].get!bool : true;
        subnet.createdAt = Clock.currTime().toUnixTime();
        
        if ("metadata" in data && data["metadata"].type == Json.Type.object) {
            foreach (string key, value; data["metadata"].byKeyValue) {
                subnet.metadata[key] = value.get!string;
            }
        }
        
        if ("dnsServers" in data) {
            foreach (dns; data["dnsServers"]) {
                subnet.dnsServers ~= dns.get!string;
            }
        }
        
        subnets[subnet.id] = subnet;
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeSubnet(subnet));
    }

    void deleteSubnet(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in subnets) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Subnet not found"]);
            return;
        }
        
        subnets.remove(id);
        res.statusCode = HTTPStatus.noContent;
        res.writeVoidBody();
    }

    // Security group operations
    void listSecurityGroups(HTTPServerRequest req, HTTPServerResponse res) {
        auto tenantId = getTenantIdFromRequest(req);
        
        JSONValue[] sgList;
        foreach (sg; securityGroups) {
            if (sg.tenantId == tenantId) {
                sgList ~= serializeSecurityGroup(sg);
            }
        }
        res.writeJsonBody(["securityGroups": sgList]);
    }

    void getSecurityGroup(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in securityGroups) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Security group not found"]);
            return;
        }
        res.writeJsonBody(serializeSecurityGroup(securityGroups[id]));
    }

    void createSecurityGroup(HTTPServerRequest req, HTTPServerResponse res) {
        auto data = req.json;
        auto tenantId = getTenantIdFromRequest(req);
        
        auto sg = SecurityGroup();
        sg.id = randomUUID().toString();
        sg.name = data["name"].get!string;
        sg.tenantId = tenantId;
        sg.description = ("description" in data) ? data["description"].get!string : "";
        sg.createdAt = Clock.currTime().toUnixTime();
        sg.updatedAt = sg.createdAt;
        
        securityGroups[sg.id] = sg;
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeSecurityGroup(sg));
    }

    void deleteSecurityGroup(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in securityGroups) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Security group not found"]);
            return;
        }
        
        securityGroups.remove(id);
        res.statusCode = HTTPStatus.noContent;
        res.writeVoidBody();
    }

    void addSecurityRule(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        if (id !in securityGroups) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Security group not found"]);
            return;
        }
        
        auto data = req.json;
        auto rule = Rule();
        rule.id = randomUUID().toString();
        rule.direction = data["direction"].get!string;
        rule.protocol = data["protocol"].get!string;
        rule.portMin = cast(int)data["portMin"].get!long;
        rule.portMax = cast(int)data["portMax"].get!long;
        rule.cidr = data["cidr"].get!string;
        
        securityGroups[id].rules ~= rule;
        securityGroups[id].updatedAt = Clock.currTime().toUnixTime();
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeRule(rule));
    }

    void removeSecurityRule(HTTPServerRequest req, HTTPServerResponse res) {
        auto id = req.params["id"];
        auto ruleId = req.params["ruleId"];
        
        if (id !in securityGroups) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Security group not found"]);
            return;
        }
        
        Rule[] newRules;
        bool found = false;
        foreach (rule; securityGroups[id].rules) {
            if (rule.id != ruleId) {
                newRules ~= rule;
            } else {
                found = true;
            }
        }
        
        if (!found) {
            res.statusCode = HTTPStatus.notFound;
            res.writeJsonBody(["error": "Rule not found"]);
            return;
        }
        
        securityGroups[id].rules = newRules;
        securityGroups[id].updatedAt = Clock.currTime().toUnixTime();
        
        res.statusCode = HTTPStatus.noContent;
        res.writeVoidBody();
    }

    string getTenantIdFromRequest(HTTPServerRequest req) {
        if ("X-Tenant-ID" in req.headers) {
            return req.headers["X-Tenant-ID"];
        }
        return "default";
    }

    Json serializeNetwork(Network network) {
        return Json([
            "id": Json(network.id),
            "name": Json(network.name),
            "tenantId": Json(network.tenantId),
            "cidr": Json(network.cidr),
            "status": Json(network.status),
            "createdAt": Json(network.createdAt),
            "updatedAt": Json(network.updatedAt),
            "metadata": serializeToJson(network.metadata)
        ]);
    }

    Json serializeSubnet(Subnet subnet) {
        Json[] dnsArray;
        foreach (dns; subnet.dnsServers) {
            dnsArray ~= Json(dns);
        }
        
        return Json([
            "id": Json(subnet.id),
            "name": Json(subnet.name),
            "tenantId": Json(subnet.tenantId),
            "networkId": Json(subnet.networkId),
            "cidr": Json(subnet.cidr),
            "gateway": Json(subnet.gateway),
            "dhcpEnabled": Json(subnet.dhcpEnabled),
            "dnsServers": Json(dnsArray),
            "createdAt": Json(subnet.createdAt),
            "metadata": serializeToJson(subnet.metadata)
        ]);
    }

    Json serializeSecurityGroup(SecurityGroup sg) {
        Json[] rulesList;
        foreach (rule; sg.rules) {
            rulesList ~= serializeRule(rule);
        }
        
        return Json([
            "id": Json(sg.id),
            "name": Json(sg.name),
            "tenantId": Json(sg.tenantId),
            "description": Json(sg.description),
            "rules": Json(rulesList),
            "createdAt": Json(sg.createdAt),
            "updatedAt": Json(sg.updatedAt)
        ]);
    }

    Json serializeRule(Rule rule) {
        return Json([
            "id": Json(rule.id),
            "direction": Json(rule.direction),
            "protocol": Json(rule.protocol),
            "portMin": Json(rule.portMin),
            "portMax": Json(rule.portMax),
            "cidr": Json(rule.cidr)
        ]);
    }
}

void main() {
    auto settings = new HTTPServerSettings;
    settings.port = 8083;
    settings.bindAddresses = ["0.0.0.0"];
    
    auto router = new URLRouter;
    auto service = new NetworkService();
    service.setupRoutes(router);
    
    logInfo("Network Service starting on port %d", settings.port);
    listenHTTP(settings, router);
    
    runApplication();
}
