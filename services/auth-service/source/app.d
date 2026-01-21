module app;

import vibe.vibe;
import std.stdio;
import std.json;
import std.uuid;
import std.datetime;
import std.digest.sha;
import std.base64;

/**
 * Auth Service - Handles authentication and authorization with multi-tenancy
 */

struct Tenant {
    string id;
    string name;
    string description;
    bool active;
    long createdAt;
    long updatedAt;
    JSONValue metadata;
}

struct User {
    string id;
    string username;
    string email;
    string passwordHash;
    string tenantId;
    string role; // admin, user, viewer
    bool active;
    long createdAt;
    long lastLogin;
}

struct ApiKey {
    string id;
    string key;
    string userId;
    string name;
    string[] scopes;
    bool active;
    long createdAt;
    long expiresAt;
}

struct Session {
    string id;
    string userId;
    string tenantId;
    string token;
    long createdAt;
    long expiresAt;
}

class AuthService {
    private User[string] users;
    private ApiKey[string] apiKeys;
    private Session[string] sessions;
    private Tenant[string] tenants;

    this() {
        // Create default tenant
        auto defaultTenant = Tenant();
        defaultTenant.id = randomUUID().toString();
        defaultTenant.name = "Default Tenant";
        defaultTenant.description = "Default system tenant";
        defaultTenant.active = true;
        defaultTenant.createdAt = Clock.currTime().toUnixTime();
        defaultTenant.updatedAt = defaultTenant.createdAt;
        defaultTenant.metadata = JSONValue(["system": "true"]);
        tenants[defaultTenant.id] = defaultTenant;
        
        // Create default admin user
        auto admin = User();
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
        auto username = data["username"].str;
        auto password = data["password"].str;
        
        User* foundUser = null;
        foreach (ref user; users) {
            if (user.username == username && user.active) {
                foundUser = &user;
                break;
            }
        }
        
        if (foundUser is null || foundUser.passwordHash != hashPassword(password)) {
            res.statusCode = HTTPStatus.unauthorized;
            res.writeJsonBody(["error": "Invalid credentials"]);
            returenantId = foundUser.tenantId;
        session.token = generateToken();
        session.createdAt = Clock.currTime().toUnixTime();
        session.expiresAt = session.createdAt + 3600 * 24; // 24 hours
        
        sessions[session.id] = session;
        foundUser.lastLogin = Clock.currTime().toUnixTime();
        
        res.writeJsonBody([
            "token": session.token,
            "expiresAt": session.expiresAt,
            "tenantId": session.tenantIddAt + 3600 * 24; // 24 hours
        
        sessions[session.id] = session;
        foundUser.lastLogin = Clock.currTime().toUnixTime();
        
        res.writeJsonBody([
            "token": session.token,
            "expiresAt": session.expiresAt,
            "user": serializeUser(*foundUser)
        ]);
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
        
        Session* foundSession = null;
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
        res.writeJsonBody(["valid": false, "error": "Invalid or expired token"]);
    }

    void listUsers(HTTPServerRequest req, HTTPServerResponse res) {
        if (!isAuthenticated(req)) {
            res.statusCode = HTTPStatus.unauthorized;
            res.writeJsonBody(["error": "Unauthorized"]);
        auto tenantId = getTenantIdFromRequest(req);
        JSONValue[] userList;
        foreach (user; users) {
            // Only show users from the same tenant
            if (user.tenantId == tenantId) {
                userList ~= serializeUser(user);
            }
        JSONValue[] userList;
        foreach (user; users) {
            userList ~= serializeUser(user);
        }
        res.writeJsonBody(["users": userList]);
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
        
        auto user = User();
        user.id = randomUUID().toString();
        user.username = data["username"].str;
        user.email = data["email"].str;
        user.passwordHash = hashPassword(data["password"].str);
        user.tenantId = data.get("tenantId", JSONValue(tenantId)).str
        auto user = User();
        user.id = randomUUID().toString();
        user.username = data["username"].str;
        user.email = data["email"].str;
        user.passwordHash = hashPassword(data["password"].str);
        user.role = data.get("role", JSONValue("user")).str;
        user.active = true;
        user.createdAt = Clock.currTime().toUnixTime();
        user.lastLogin = 0;
        
        users[user.id] = user;
        
        res.statusCode = HTTPStatus.created;
        res.writeJsonBody(serializeUser(user));
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
        if ("email" in data) users[id].email = data["email"].str;
        if ("role" in data) users[id].role = data["role"].str;
        if ("active" in data) users[id].active = data["active"].boolean;
        if ("password" in data) users[id].passwordHash = hashPassword(data["password"].str);
        
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
        
        JSONValue[] keyList;
        foreach (apiKey; apiKeys) {
            keyList ~= serializeApiKey(apiKey);
        }
        res.writeJsonBody(["apiKeys": keyList]);
    }

    void createApiKey(HTTPServerRequest req, HTTPServerResponse res) {
        if (!isAuthenticated(req)) {
            res.statusCode = HTTPStatus.unauthorized;
            res.writeJsonBody(["error": "Unauthorized"]);
            return;
        }
        
        auto data = req.json;
        
        auto apiKey = ApiKey();
        apiKey.id = randomUUID().toString();
        apiKey.key = generateToken();
        apiKey.userId = data["userId"].str;
        apiKey.name = data["name"].str;
        apiKey.active = true;
        apiKey.createdAt = Clock.currTime().toUnixTime();
        apiKey.expiresAt = apiKey.createdAt + 3600 * 24 * 365; // 1 year
        
        if ("scopes" in data) {
            foreach (scope_; data["scopes"].array) {
                apiKey.scopes ~= scope_.str;
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
            if (auth.length > 7 && auth[0..7] == "Bearer ") {
                return auth[7..$];
            }
        }
        return "";
    }

    bool isAuthenticated(HTTPServerRequest req) {
        auto token = getTokenFromRequest(req);
        if (token.length == 0) return false;
        
        foreach (session; sessions) {
    void listTenants(HTTPServerRequest req, HTTPServerResponse res) {
        if (!isAuthenticated(req)) {
            res.statusCode = HTTPStatus.unauthorized;
            res.writeJsonBody(["error": "Unauthorized"]);
            return;
        }
        
        JSONValue[] tenantList;
        foreach (tenant; tenants) {
            tenantList ~= serializeTenant(tenant);
        }
        res.writeJsonBody(["tenants": tenantList]);
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
        
        auto tenant = Tenant();
        tenant.id = randomUUID().toString();
        tenant.name = data["name"].str;
        tenant.description = data.get("description", JSONValue("")).str;
        tenant.active = true;
        tenant.createdAt = Clock.currTime().toUnixTime();
        tenant.updatedAt = tenant.createdAt;
        tenant.metadata = data.get("metadata", JSONValue(["": ""]));
        
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
        if ("name" in data) tenants[id].name = data["name"].str;
        if ("description" in data) tenants[id].description = data["description"].str;
        if ("active" in data) tenants[id].active = data["active"].boolean;
        if ("metadata" in data) tenants[id].metadata = data["metadata"];
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
                res.writeJsonBody(["error": "Cannot delete tenant with active users"]);
                return;
            }
        }
        
        tenants.remove(id);
        res.statusCode = HTTPStatus.noContent;
        res.writeVoidBody();
    }

    string getTenantIdFromRequest(HTTPServerRequest req) {
        auto token = getTokenFromRequest(req);
        if (token.length == 0) return "";
        
        foreach (session; sessions) {
            if (session.token == token && session.expiresAt >= Clock.currTime().toUnixTime()) {
                return session.tenantId;
            }
        }
        return "";
    }

    JSONValue serializeUser(User user) {
        return JSONValue([
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "tenantId": user.tenantId,
            "role": user.role,
            "active": user.active,
            "createdAt": user.createdAt,
            "lastLogin": user.lastLogin
        ]);
    }
    
    JSONValue serializeTenant(Tenant tenant) {
        return JSONValue([
            "id": tenant.id,
            "name": tenant.name,
            "description": tenant.description,
            "active": tenant.active,
            "createdAt": tenant.createdAt,
            "updatedAt": tenant.updatedAt,
            "metadata": tenant.metadata
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "role": user.role,
            "active": user.active,
            "createdAt": user.createdAt,
            "lastLogin": user.lastLogin
        ]);
    }

    JSONValue serializeApiKey(ApiKey apiKey) {
        return JSONValue([
            "id": apiKey.id,
            "key": apiKey.key,
            "userId": apiKey.userId,
            "name": apiKey.name,
            "scopes": JSONValue(apiKey.scopes),
            "active": apiKey.active,
            "createdAt": apiKey.createdAt,
            "expiresAt": apiKey.expiresAt
        ]);
    }
}

void main() {
    auto settings = new HTTPServerSettings;
    settings.port = 8084;
    settings.bindAddresses = ["0.0.0.0"];
    
    auto router = new URLRouter;
    auto service = new AuthService();
    service.setupRoutes(router);
    
    logInfo("Auth Service starting on port %d", settings.port);
    listenHTTP(settings, router);
    
    runApplication();
}
