struct Alert {
    string id;
    string name;
    string tenantId;
    string severity; // info, warning, critical
    string message;
    string source;
    bool active;
    long triggeredAt;
    long resolvedAt;
}