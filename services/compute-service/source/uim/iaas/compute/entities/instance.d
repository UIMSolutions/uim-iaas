
struct Instance {
    string id;
    string name;
    string tenantId;
    string type; // vm, container
    string flavor; // small, medium, large
    string status; // creating, running, stopped, error
    string imageId;
    string[] networkIds;
    string[] volumeIds;
    long createdAt;
    long updatedAt;
    string[string] metadata;
}