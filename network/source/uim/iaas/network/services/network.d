/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.network.services.network;

import uim.iaas.network;

/**
 * Network Service - Manages virtual networks, subnets, and security groups with multi-tenancy
 */
class NetworkService {
  private NetworkEntity[string] networks;
  private SubnetEntity[string] subnets;
  private SecurityGroupEntity[string] securityGroups;

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

    Json[] networkList;
    foreach (network; networks) {
      if (network.tenantId == tenantId) {
        networkList ~= network.toJson;
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
    res.writeJsonBody(networks[id].toJson);
  }

  void createNetwork(HTTPServerRequest req, HTTPServerResponse res) {
    auto data = req.json;
    auto tenantId = getTenantIdFromRequest(req);

    auto network = new NetworkEntity();
    network.id = randomUUID().toString();
    network.name = data["name"].get!string;
    network.tenantId = tenantId;
    network.cidr = data["cidr"].get!string;
    network.status = "active";
    network.createdAt = Clock.currTime().toUnixTime();
    network.updatedAt = network.createdAt;

    if ("metadata" in data && data["metadata"].type == Json.Type.object) {
      foreach (string key, value; data["metadata"].byKeyValue) {
        network.metadata(key, value.get!string);
      }
    }

    networks[network.id] = network;

    res.statusCode = HTTPStatus.created;
    res.writeJsonBody(network.toJson);
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

    Json[] subnetList = subnets.filter!(subnet => subnet.tenantId == tenantId).map!(subnet => subnet.toJson).array;
    res.writeJsonBody(["subnets": subnetList]);
  }

  void getSubnet(HTTPServerRequest req, HTTPServerResponse res) {
    auto id = req.params["id"];
    if (id !in subnets) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "Subnet not found"]);
      return;
    }
    res.writeJsonBody(subnets[id].toJson);
  }

  void createSubnet(HTTPServerRequest req, HTTPServerResponse res) {
    auto data = req.json;
    auto tenantId = getTenantIdFromRequest(req);

    auto subnet = new SubnetEntity();
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
        subnet.metadata(key, value.get!string);
      }
    }

    if ("dnsServers" in data) {
      foreach (dns; data["dnsServers"]) {
        subnet.dnsServers ~= dns.get!string;
      }
    }

    subnets[subnet.id] = subnet;

    res.statusCode = HTTPStatus.created;
    res.writeJsonBody(subnet.toJson);
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

    Json[] sgList = securityGroups.filter!(sg => sg.tenantId == tenantId).map!(sg => sg.toJson).array;
    res.writeJsonBody(["securityGroups": sgList]);
  }

  void getSecurityGroup(HTTPServerRequest req, HTTPServerResponse res) {
    auto id = req.params["id"];
    if (id !in securityGroups) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "Security group not found"]);
      return;
    }
    res.writeJsonBody(securityGroups[id].toJson);
  }

  void createSecurityGroup(HTTPServerRequest req, HTTPServerResponse res) {
    auto data = req.json;
    auto tenantId = getTenantIdFromRequest(req);

    auto sg = new SecurityGroupEntity();
    sg.id = randomUUID().toString();
    sg.name = data["name"].get!string;
    sg.tenantId = tenantId;
    sg.description = ("description" in data) ? data["description"].get!string : "";
    sg.createdAt = Clock.currTime().toUnixTime();
    sg.updatedAt = sg.createdAt;

    securityGroups[sg.id] = sg;

    res.statusCode = HTTPStatus.created;
    res.writeJsonBody(sg.toJson);
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
    auto rule = new RuleEntity();
    rule.id = randomUUID().toString();
    rule.direction = data["direction"].get!string;
    rule.protocol = data["protocol"].get!string;
    rule.portMin = cast(int)data["portMin"].get!long;
    rule.portMax = cast(int)data["portMax"].get!long;
    rule.cidr = data["cidr"].get!string;

    securityGroups[id].addRule(rule);
    securityGroups[id].updatedAt = Clock.currTime().toUnixTime();

    res.statusCode = HTTPStatus.created;
    res.writeJsonBody(rule.toJson);
  }

  void removeSecurityRule(HTTPServerRequest req, HTTPServerResponse res) {
    auto id = req.params["id"];
    auto ruleId = req.params["ruleId"];

    if (id !in securityGroups) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "Security group not found"]);
      return;
    }

    RuleEntity[] newRules;
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
}
