module objectstore.config;

import std.process : environment;
import std.conv : to;
import std.file : exists, mkdirRecurse;

struct Config
{
    ushort port = 8080;
    string storagePath = "./data/storage";
    string metadataPath = "./data/metadata";
    string authToken = "default-secret-token";
    ulong maxObjectSize = 5 * 1024 * 1024 * 1024; // 5GB default
    bool enableAuth = true;

    static Config load()
    {
        Config config;
        
        // Load from environment variables
        if (auto port = environment.get("PORT"))
            config.port = port.to!ushort;
        
        if (auto storagePath = environment.get("STORAGE_PATH"))
            config.storagePath = storagePath;
        
        if (auto metadataPath = environment.get("METADATA_PATH"))
            config.metadataPath = metadataPath;
        
        if (auto authToken = environment.get("AUTH_TOKEN"))
            config.authToken = authToken;
        
        if (auto maxSize = environment.get("MAX_OBJECT_SIZE"))
            config.maxObjectSize = maxSize.to!ulong;
        
        if (auto enableAuth = environment.get("ENABLE_AUTH"))
            config.enableAuth = enableAuth == "true";

        // Ensure storage directories exist
        if (!exists(config.storagePath))
            mkdirRecurse(config.storagePath);
        
        if (!exists(config.metadataPath))
            mkdirRecurse(config.metadataPath);

        return config;
    }
}
