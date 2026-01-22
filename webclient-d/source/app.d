import vibe.vibe;
import vibe.web.web;
import std.conv;
import std.json;
import std.stdio;
import std.algorithm;

// Configuration
immutable string API_GATEWAY = "http://localhost:8080/api/v1";

// Session data
struct UserSession {
    string username;
    string token;
    string tenantId;
    bool isAuthenticated;
}

// Web Interface
@path("/")
class WebInterface {
    private {
        SessionVar!(UserSession, "userSession") m_session;
    }

    // Home page - redirects to login or dashboard
    @path("/")
    void getIndex() {
        if (m_session.isAuthenticated) {
            redirect("/dashboard");
        } else {
            redirect("/login");
        }
    }

    // Login page
    @path("/login")
    void getLogin(string _error = null) {
        auto error = _error;
        render!("login.dt", error);
    }

    // Login form submission
    @path("/login")
    @method(HTTPMethod.POST)
    void postLogin(string username, string password) {
        try {
            writeln("Attempting login for user: ", username, " with password: ", password);

            auto response = performLogin(username, password);
            writeln("Login response: ", response);
            
            UserSession session;
            session.username = response["username"].get!string;
            session.token = response["token"].get!string;
            session.tenantId = response["tenantId"].get!string;
            session.isAuthenticated = true;
            m_session = session;
            
            redirect("/dashboard");
        } catch (Exception e) {
            redirect("/login?_error=" ~ e.msg);
        }
    }

    // Logout
    @path("/logout")
    void getLogout() {
        UserSession session;
        session.username = "";
        session.token = "";
        session.tenantId = "";
        session.isAuthenticated = false;
        m_session = session;
        terminateSession();
        redirect("/login");
    }

    // Dashboard
    @path("/dashboard")
    void getDashboard(string _tab = "compute") {
        enforceAuthenticated();
        
        auto username = m_session.username;
        auto activeTab = _tab;
        
        render!("dashboard.dt", username, activeTab);
    }

    // Compute instances page
    @path("/compute")
    void getCompute(string _error = null) {
        enforceAuthenticated();
        
        try {
            auto instances = getInstances();
            auto username = m_session.username;
            string error = _error;
            render!("compute.dt", username, instances, error);
        } catch (Exception e) {
            redirect("/compute?_error=" ~ e.msg);
        }
    }

    // Create instance form
    @path("/compute/create")
    void getComputeCreate() {
        enforceAuthenticated();
        auto username = m_session.username;
        render!("compute_create.dt", username);
    }

    // Create instance submission
    @path("/compute/create")
    @method(HTTPMethod.POST)
    void postComputeCreate(string name, string type, string flavor, string imageId) {
        enforceAuthenticated();
        
        try {
            createInstance(name, type, flavor, imageId);
            redirect("/compute");
        } catch (Exception e) {
            redirect("/compute?_error=" ~ e.msg);
        }
    }

    // Start instance
    @path("/compute/:id/start")
    @method(HTTPMethod.POST)
    void postStartInstance(string _id) {
        enforceAuthenticated();
        
        try {
            startInstance(_id);
            redirect("/compute");
        } catch (Exception e) {
            redirect("/compute?_error=" ~ e.msg);
        }
    }

    // Stop instance
    @path("/compute/:id/stop")
    @method(HTTPMethod.POST)
    void postStopInstance(string _id) {
        enforceAuthenticated();
        
        try {
            stopInstance(_id);
            redirect("/compute");
        } catch (Exception e) {
            redirect("/compute?_error=" ~ e.msg);
        }
    }

    // Delete instance
    @path("/compute/:id/delete")
    @method(HTTPMethod.POST)
    void postDeleteInstance(string _id) {
        enforceAuthenticated();
        
        try {
            deleteInstance(_id);
            redirect("/compute");
        } catch (Exception e) {
            redirect("/compute?_error=" ~ e.msg);
        }
    }

    // Network page
    @path("/network")
    void getNetwork(string _error = null) {
        enforceAuthenticated();
        
        try {
            auto networks = getNetworks();
            auto username = m_session.username;
            string error = _error;
            render!("network.dt", username, networks, error);
        } catch (Exception e) {
            redirect("/network?_error=" ~ e.msg);
        }
    }

    // Create network form
    @path("/network/create")
    void getNetworkCreate() {
        enforceAuthenticated();
        auto username = m_session.username;
        render!("network_create.dt", username);
    }

    // Create network submission
    @path("/network/create")
    @method(HTTPMethod.POST)
    void postNetworkCreate(string name, string cidr) {
        enforceAuthenticated();
        
        try {
            createNetwork(name, cidr);
            redirect("/network");
        } catch (Exception e) {
            redirect("/network?_error=" ~ e.msg);
        }
    }

    // Delete network
    @path("/network/:id/delete")
    @method(HTTPMethod.POST)
    void postDeleteNetwork(string _id) {
        enforceAuthenticated();
        
        try {
            deleteNetwork(_id);
            redirect("/network");
        } catch (Exception e) {
            redirect("/network?_error=" ~ e.msg);
        }
    }

    // Storage page
    @path("/storage")
    void getStorage(string _error = null) {
        enforceAuthenticated();
        
        try {
            auto volumes = getVolumes();
            auto username = m_session.username;
            string error = _error;
            render!("storage.dt", username, volumes, error);
        } catch (Exception e) {
            redirect("/storage?_error=" ~ e.msg);
        }
    }

    // Create volume form
    @path("/storage/create")
    void getStorageCreate() {
        enforceAuthenticated();
        auto username = m_session.username;
        render!("storage_create.dt", username);
    }

    // Create volume submission
    @path("/storage/create")
    @method(HTTPMethod.POST)
    void postStorageCreate(string name, string type, int sizeGB) {
        enforceAuthenticated();
        
        try {
            createVolume(name, type, sizeGB);
            redirect("/storage");
        } catch (Exception e) {
            redirect("/storage?_error=" ~ e.msg);
        }
    }

    // Delete volume
    @path("/storage/:id/delete")
    @method(HTTPMethod.POST)
    void postDeleteVolume(string _id) {
        enforceAuthenticated();
        
        try {
            deleteVolume(_id);
            redirect("/storage");
        } catch (Exception e) {
            redirect("/storage?_error=" ~ e.msg);
        }
    }

    // Monitoring page
    @path("/monitoring")
    void getMonitoring(string _error = null) {
        enforceAuthenticated();
        
        try {
            auto metrics = getMetrics();
            auto username = m_session.username;
            string error = _error;
            render!("monitoring.dt", username, metrics, error);
        } catch (Exception e) {
            redirect("/monitoring?_error=" ~ e.msg);
        }
    }

    private void enforceAuthenticated() {
        if (!m_session.isAuthenticated) {
            redirect("/login");
        }
    }

    // API Helper Methods
    private Json performLogin(string username, string password) {
        Json result;
        
        writeln("Performing login API request...", API_GATEWAY ~ "/auth/login");
        requestHTTP(API_GATEWAY ~ "/auth/login",
            (scope req) {
                req.method = HTTPMethod.POST;
                req.headers["Content-Type"] = "application/json";
                
                Json body = Json.emptyObject;
                body["username"] = username;
                body["password"] = password;

                writeln("Body: ", body);
                req.writeJsonBody(body);
            },
            (scope res) {
                enforceHTTP(res.statusCode == 200, HTTPStatus.unauthorized, "Login failed");
                result = res.readJson();
            }
        );
        
        return result;
    }

    private Json[] getInstances() {
        auto json = apiRequest("/compute/instances", HTTPMethod.GET);
        return json.get!(Json[]);
    }

    private void createInstance(string name, string type, string flavor, string imageId) {
        Json body = Json.emptyObject;
        body["name"] = name;
        body["type"] = type;
        body["flavor"] = flavor;
        body["imageId"] = imageId;
        
        apiRequest("/compute/instances", HTTPMethod.POST, body);
    }

    private void startInstance(string id) {
        apiRequest("/compute/instances/" ~ id ~ "/start", HTTPMethod.POST);
    }

    private void stopInstance(string id) {
        apiRequest("/compute/instances/" ~ id ~ "/stop", HTTPMethod.POST);
    }

    private void deleteInstance(string id) {
        apiRequest("/compute/instances/" ~ id, HTTPMethod.DELETE);
    }

    private Json[] getNetworks() {
        auto json = apiRequest("/network/networks", HTTPMethod.GET);
        return json.get!(Json[]);
    }

    private void createNetwork(string name, string cidr) {
        Json body = Json.emptyObject;
        body["name"] = name;
        body["cidr"] = cidr;
        
        apiRequest("/network/networks", HTTPMethod.POST, body);
    }

    private void deleteNetwork(string id) {
        apiRequest("/network/networks/" ~ id, HTTPMethod.DELETE);
    }

    private Json[] getVolumes() {
        auto json = apiRequest("/storage/volumes", HTTPMethod.GET);
        return json.get!(Json[]);
    }

    private void createVolume(string name, string type, int sizeGB) {
        Json body = Json.emptyObject;
        body["name"] = name;
        body["type"] = type;
        body["sizeGB"] = sizeGB;
        
        apiRequest("/storage/volumes", HTTPMethod.POST, body);
    }

    private void deleteVolume(string id) {
        apiRequest("/storage/volumes/" ~ id, HTTPMethod.DELETE);
    }

    private Json getMetrics() {
        auto instances = getInstances();
        auto networks = getNetworks();
        auto volumes = getVolumes();
        
        Json metrics = Json.emptyObject;
        metrics["instances"] = instances.length;
        metrics["networks"] = networks.length;
        metrics["volumes"] = volumes.length;
        
        return metrics;
    }

    private Json apiRequest(string path, HTTPMethod method, Json body = Json.undefined) {
        Json result = Json.emptyObject;
        
        requestHTTP(API_GATEWAY ~ path,
            (scope req) {
                req.method = method;
                req.headers["Content-Type"] = "application/json";
                req.headers["Authorization"] = "Bearer " ~ m_session.token;
                req.headers["X-Tenant-ID"] = m_session.tenantId;
                
                if (body.type != Json.Type.undefined) {
                    req.writeJsonBody(body);
                }
            },
            (scope res) {
                if (res.statusCode == 204) {
                    result = Json.emptyObject;
                    return;
                }
                
                enforceHTTP(res.statusCode >= 200 && res.statusCode < 300, 
                           cast(HTTPStatus)res.statusCode, "API request failed");
                
                if (res.statusCode == 200 || res.statusCode == 201) {
                    result = res.readJson();
                } else {
                    result = Json.emptyObject;
                }
            }
        );
        
        return result;
    }
}

shared static this() {
    auto settings = new HTTPServerSettings;
    settings.port = 8090;
    settings.bindAddresses = ["0.0.0.0"];
    settings.sessionStore = new MemorySessionStore;
    
    auto router = new URLRouter;
    router.registerWebInterface(new WebInterface);
    router.get("*", serveStaticFiles("public/"));
    
    listenHTTP(settings, router);
    
    logInfo("UIM IaaS Web Client running on http://localhost:8090");
}
