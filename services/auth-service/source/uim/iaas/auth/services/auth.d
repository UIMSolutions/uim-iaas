module uim.iaas.auth.services.auth;

import uim.iaas.auth;

class AuthService {
  private UserEntity[string] users;
  private ApiKeyEntity[string] apiKeys;
  private SessionEntity[string] sessions;
  private TenantEntity[string] tenants;

  this() {
    // Create default tenant
    auto defaultTenant = TenantEntity();
    defaultTenant.id = randomUUID().toString();
    defaultTenant.name = "Default Tenant";
    defaultTenant.description = "Default system tenant";
    defaultTenant.active = true;
    defaultTenant.createdAt = Clock.currTime().toUnixTime();
    defaultTenant.updatedAt = defaultTenant.createdAt;
    defaultTenant.metadata = ["system": "true"];
    tenants[defaultTenant.id] = defaultTenant;

    // Create default admin user
    auto admin = UserEntity();
    admin.id = randomUUID().toString();
    admin.username = "admin";
    admin.email = "admin@uim-iaas.local";
    admin.passwordHash = hashPassword("admin123");
    admin.tenantId = defaultTenant.id;
    admin.role = "admin";
    admin.active = true;
    admin.createdAt = Clock.currTime().toUnixTime();
    admin.lastLogin = 0;
    users[admin.id] = admin;
  }

  void setupRoutes(URLRouter router) {
    router.get("/health", &healthCheck);

    // Authentication
    router.post("/api/v1/auth/login", &login);
    router.post("/api/v1/auth/logout", &logout);
    router.post("/api/v1/auth/refresh", &refreshToken);
    router.get("/api/v1/auth/verify", &verifyToken);

    // Tenant management
    router.get("/api/v1/auth/tenants", &listTenants);
    router.get("/api/v1/auth/tenants/:id", &getTenant);
    router.post("/api/v1/auth/tenants", &createTenant);
    router.put("/api/v1/auth/tenants/:id", &updateTenant);
    router.delete_("/api/v1/auth/tenants/:id", &deleteTenant);

    // User management
    router.get("/api/v1/auth/users", &listUsers);
    router.get("/api/v1/auth/users/:id", &getUser);
    router.post("/api/v1/auth/users", &createUser);
    router.put("/api/v1/auth/users/:id", &updateUser);
    router.delete_("/api/v1/auth/users/:id", &deleteUser);

    // API Key management
    router.get("/api/v1/auth/api-keys", &listApiKeys);
    router.post("/api/v1/auth/api-keys", &createApiKey);
    router.delete_("/api/v1/auth/api-keys/:id", &deleteApiKey);
  }

  void healthCheck(HTTPServerRequest req, HTTPServerResponse res) {
    res.writeJsonBody(["status": "healthy", "service": "auth-service"]);
  }

  void login(HTTPServerRequest req, HTTPServerResponse res) {
    auto data = req.json;
    auto username = data["username"].get!string;
    auto password = data["password"].get!string;

    UserEntity* foundUser = null;
    foreach (ref user; users) {
      if (user.username == username && user.active) {
        foundUser = &user;
        break;
      }
    }

    if (foundUser is null || foundUser.passwordHash != hashPassword(password)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Invalid credentials"]);
      
      SessionEntity session = new SessionEntity();
      session.tenantId = foundUser.tenantId;
      session.token = generateToken();
      session.createdAt = Clock.currTime().toUnixTime();
      session.expiresAt = session.createdAt + 3600 * 24; // 24 hours

      sessions[session.id] = session;
      foundUser.lastLogin = Clock.currTime().toUnixTime();

      res.writeJsonBody([
        "token": Json(session.token),
        "expiresAt": Json(session.expiresAt),
        "tenantId": Json(session.tenantId),
        "user": serializeUser(*foundUser)
      ]);
    }
  }

  void logout(HTTPServerRequest req, HTTPServerResponse res) {
    auto token = getTokenFromRequest(req);
    if (token.length == 0) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "No token provided"]);
      return;
    }

    foreach (id, session; sessions) {
      if (session.token == token) {
        sessions.remove(id);
        break;
      }
    }

    res.writeJsonBody(["message": "Logged out successfully"]);
  }

  void refreshToken(HTTPServerRequest req, HTTPServerResponse res) {
    auto token = getTokenFromRequest(req);
    if (token.length == 0) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "No token provided"]);
      return;
    }

    SessionEntity* foundSession = null;
    foreach (ref session; sessions) {
      if (session.token == token) {
        foundSession = &session;
        break;
      }
    }

    if (foundSession is null || foundSession.expiresAt < Clock.currTime().toUnixTime()) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Invalid or expired token"]);
      return;
    }

    // Extend session
    foundSession.expiresAt = Clock.currTime().toUnixTime() + 3600 * 24;

    res.writeJsonBody([
      "token": foundSession.token,
      "expiresAt": foundSession.expiresAt
    ]);
  }

  void verifyToken(HTTPServerRequest req, HTTPServerResponse res) {
    auto token = getTokenFromRequest(req);
    if (token.length == 0) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["valid": false, "error": "No token provided"]);
      return;
    }

    foreach (session; sessions) {
      if (session.token == token) {
        if (session.expiresAt >= Clock.currTime().toUnixTime()) {
          if (session.userId in users) {
            res.writeJsonBody([
              "tenantId": session.tenantId,
              "valid": true,
              "userId": session.userId,
              "user": serializeUser(users[session.userId])
            ]);
            return;
          }
        }
      }
    }

    res.statusCode = HTTPStatus.unauthorized;
    res.writeJsonBody([
        "valid": false,
        "error": "Invalid or expired token"
      ]);
  }

  void listUsers(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }
    auto tenantId = getTenantIdFromRequest(req);
    Json[] userList;
    foreach (user; users) {
      // Only show users from the same tenant
      if (user.tenantId == tenantId) {
        userList ~= serializeUser(user);
      }
    }
    res.writeJsonBody(Json(["users": Json(userList)]));
  }

  void getUser(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto id = req.params["id"];
    if (id !in users) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "User not found"]);
      return;
    }

    res.writeJsonBody(serializeUser(users[id]));
  }

  void createUser(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      auto tenantId = getTenantIdFromRequest(req);

      auto user = new UserEntity();
      user.id = randomUUID().toString();
      user.username = data["username"].get!string;
      user.email = data["email"].get!string;
      user.passwordHash = hashPassword(data["password"].get!string);
      user.tenantId = ("tenantId" in data) ? data["tenantId"].get!string : tenantId;
      user.role = ("role" in data) ? data["role"].get!string : "user";
      user.active = true;
      user.createdAt = Clock.currTime().toUnixTime();
      user.lastLogin = 0;

      users[user.id] = user;

      res.statusCode = HTTPStatus.created;
      res.writeJsonBody(serializeUser(user));
    }
  }

  void updateUser(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto id = req.params["id"];
    if (id !in users) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "User not found"]);
      return;
    }

    auto data = req.json;
    if ("email" in data)
      users[id].email = data["email"].get!string;
    if ("role" in data)
      users[id].role = data["role"].get!string;
    if ("active" in data)
      users[id].active = data["active"].get!bool;
    if ("password" in data)
      users[id].passwordHash = hashPassword(data["password"].get!string);

    res.writeJsonBody(serializeUser(users[id]));
  }

  void deleteUser(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto id = req.params["id"];
    if (id !in users) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "User not found"]);
      return;
    }

    users.remove(id);
    res.statusCode = HTTPStatus.noContent;
    res.writeVoidBody();
  }

  void listApiKeys(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    Json[] keyList;
    foreach (apiKey; apiKeys) {
      keyList ~= serializeApiKey(apiKey);
    }
    res.writeJsonBody(Json(["apiKeys": Json(keyList)]));
  }

  void createApiKey(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto data = req.json;

    ApiKeyEntity apiKey;
    apiKey.id = randomUUID().toString();
    apiKey.key = generateToken();
    apiKey.userId = data["userId"].get!string;
    apiKey.name = data["name"].get!string;
    apiKey.active = true;
    apiKey.createdAt = Clock.currTime().toUnixTime();
    apiKey.expiresAt = apiKey.createdAt + 3600 * 24 * 365; // 1 year

    if ("scopes" in data) {
      foreach (scope_; data["scopes"]) {
        apiKey.scopes ~= scope_.get!string;
      }
    }

    apiKeys[apiKey.id] = apiKey;

    res.statusCode = HTTPStatus.created;
    res.writeJsonBody(serializeApiKey(apiKey));
  }

  void deleteApiKey(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto id = req.params["id"];
    if (id !in apiKeys) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "API key not found"]);
      return;
    }

    apiKeys.remove(id);
    res.statusCode = HTTPStatus.noContent;
    res.writeVoidBody();
  }

  // Helper methods
  string hashPassword(string password) {
    return toHexString(sha256Of(password)).idup;
  }

  string generateToken() {
    return toHexString(sha256Of(randomUUID().toString())).idup;
  }

  string getTokenFromRequest(HTTPServerRequest req) {
    if ("Authorization" in req.headers) {
      auto auth = req.headers["Authorization"];
      if (auth.length > 7 && auth[0 .. 7] == "Bearer ") {
        return auth[7 .. $];
      }
    }
    return "";
  }

  bool isAuthenticated(HTTPServerRequest req) {
    auto token = getTokenFromRequest(req);
    if (token.length == 0)
      return false;

    foreach (session; sessions) {
      if (session.token == token && session.expiresAt > Clock.currTime().toUnixTime()) {
        return true;
      }
    }
    return false;
  }

  void listTenants(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    Json[] tenantList;
    foreach (tenant; tenants) {
      tenantList ~= serializeTenant(tenant);
    }
    res.writeJsonBody(Json(["tenants": Json(tenantList)]));
  }

  void getTenant(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto id = req.params["id"];
    if (id !in tenants) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "Tenant not found"]);
      return;
    }

    res.writeJsonBody(serializeTenant(tenants[id]));
  }

  void createTenant(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto data = req.json;

    auto tenant = TenantEntity();
    tenant.id = randomUUID().toString();
    tenant.name = data["name"].get!string;
    tenant.description = ("description" in data) ? data["description"].get!string : "";
    tenant.active = true;
    tenant.createdAt = Clock.currTime().toUnixTime();
    tenant.updatedAt = tenant.createdAt;

    if ("metadata" in data && data["metadata"].type == Json.Type.object) {
      foreach (string key, value; data["metadata"].byKeyValue) {
        tenant.metadata[key] = value.get!string;
      }
    }

    tenants[tenant.id] = tenant;

    res.statusCode = HTTPStatus.created;
    res.writeJsonBody(serializeTenant(tenant));
  }

  void updateTenant(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto id = req.params["id"];
    if (id !in tenants) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "Tenant not found"]);
      return;
    }

    auto data = req.json;
    if ("name" in data)
      tenants[id].name = data["name"].get!string;
    if ("description" in data)
      tenants[id].description = data["description"].get!string;
    if ("active" in data)
      tenants[id].active = data["active"].get!bool;
    if ("metadata" in data && data["metadata"].type == Json.Type.object) {
      tenants[id].metadata.clear();
      foreach (string key, value; data["metadata"].byKeyValue) {
        tenants[id].metadata[key] = value.get!string;
      }
    }
    tenants[id].updatedAt = Clock.currTime().toUnixTime();

    res.writeJsonBody(serializeTenant(tenants[id]));
  }

  void deleteTenant(HTTPServerRequest req, HTTPServerResponse res) {
    if (!isAuthenticated(req)) {
      res.statusCode = HTTPStatus.unauthorized;
      res.writeJsonBody(["error": "Unauthorized"]);
      return;
    }

    auto id = req.params["id"];
    if (id !in tenants) {
      res.statusCode = HTTPStatus.notFound;
      res.writeJsonBody(["error": "Tenant not found"]);
      return;
    }

    // Check if tenant has users
    foreach (user; users) {
      if (user.tenantId == id) {
        res.statusCode = HTTPStatus.badRequest;
        res.writeJsonBody([
            "error": "Cannot delete tenant with active users"
          ]);
        return;
      }
    }

    tenants.remove(id);
    res.statusCode = HTTPStatus.noContent;
    res.writeVoidBody();
  }

  string getTenantIdFromRequest(HTTPServerRequest req) {
    auto token = getTokenFromRequest(req);
    if (token.length == 0)
      return "";

    foreach (session; sessions) {
      if (session.token == token && session.expiresAt >= Clock.currTime()
        .toUnixTime()) {
        return session.tenantId;
      }
    }
    return "";
  }

  Json serializeUser(UserEntity user) {
    return Json([
      "id": Json(user.id),
      "username": Json(user.username),
      "email": Json(user.email),
      "tenantId": Json(user.tenantId),
      "role": Json(user.role),
      "active": Json(user.active),
      "createdAt": Json(user.createdAt),
      "lastLogin": Json(user.lastLogin)
    ]);
  }

  Json serializeTenant(TenantEntity tenant) {
    return Json([
      "id": Json(tenant.id),
      "name": Json(tenant.name),
      "description": Json(tenant.description),
      "active": Json(tenant.active),
      "createdAt": Json(tenant.createdAt),
      "updatedAt": Json(tenant.updatedAt),
      "metadata": serializeToJson(tenant.metadata)
    ]);
  }

  Json serializeApiKey(ApiKeyEntity apiKey) {
    Json[] scopesArray;
    foreach (scope_; apiKey.scopes) {
      scopesArray ~= Json(scope_);
    }

    return Json([
      "id": Json(apiKey.id),
      "key": Json(apiKey.key),
      "userId": Json(apiKey.userId),
      "name": Json(apiKey.name),
      "scopes": Json(scopesArray),
      "active": Json(apiKey.active),
      "createdAt": Json(apiKey.createdAt),
      "expiresAt": Json(apiKey.expiresAt)
    ]);
  }
}