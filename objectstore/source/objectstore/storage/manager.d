module objectstore.storage.manager;

import std.file;
import std.path;
import std.algorithm;
import std.conv;
import std.datetime;
import std.json;
import std.digest.md;
import std.uuid;
import vibe.core.log;
import objectstore.models;

class StorageManager
{
    private string storagePath;
    private string metadataPath;

    this(string storagePath)
    {
        this.storagePath = storagePath;
        this.metadataPath = buildPath(storagePath, ".metadata");
        
        if (!exists(this.storagePath))
            mkdirRecurse(this.storagePath);
        
        if (!exists(this.metadataPath))
            mkdirRecurse(this.metadataPath);
    }

    // Container operations
    Container[] listContainers()
    {
        Container[] containers;
        
        foreach (DirEntry entry; dirEntries(storagePath, SpanMode.shallow))
        {
            if (entry.isDir && baseName(entry.name) != ".metadata")
            {
                auto container = getContainer(baseName(entry.name));
                containers ~= container;
            }
        }
        
        return containers;
    }

    Container createContainer(string name)
    {
        validateName(name);
        
        auto containerPath = buildPath(storagePath, name);
        
        if (exists(containerPath))
            throw new Exception("Container already exists: " ~ name);
        
        mkdirRecurse(containerPath);
        
        // Create metadata
        auto metadata = ContainerMetadata(
            name,
            containerPath,
            Clock.currTime().toISOExtString(),
            null
        );
        
        saveContainerMetadata(name, metadata);
        
        logInfo("Created container: %s", name);
        
        return Container(
            name,
            metadata.createdAt,
            0,
            0
        );
    }

    void deleteContainer(string name)
    {
        auto containerPath = buildPath(storagePath, name);
        
        if (!exists(containerPath))
            throw new Exception("Container not found: " ~ name);
        
        // Check if container is empty
        auto objects = listObjects(name);
        if (objects.length > 0)
            throw new Exception("Container is not empty. Delete all objects first.");
        
        rmdirRecurse(containerPath);
        
        // Delete metadata
        auto metadataFile = buildPath(metadataPath, name ~ ".json");
        if (exists(metadataFile))
            remove(metadataFile);
        
        // Delete service keys
        auto keysDir = buildPath(metadataPath, "keys", name);
        if (exists(keysDir))
            rmdirRecurse(keysDir);
        
        logInfo("Deleted container: %s", name);
    }

    Container getContainer(string name)
    {
        auto containerPath = buildPath(storagePath, name);
        
        if (!exists(containerPath))
            throw new Exception("Container not found: " ~ name);
        
        auto metadata = loadContainerMetadata(name);
        
        // Calculate stats
        ulong objectCount = 0;
        ulong totalSize = 0;
        
        foreach (DirEntry entry; dirEntries(containerPath, SpanMode.depth))
        {
            if (entry.isFile)
            {
                objectCount++;
                totalSize += entry.size;
            }
        }
        
        return Container(
            name,
            metadata.createdAt,
            objectCount,
            totalSize
        );
    }

    // Object operations
    ObjectInfo[] listObjects(string containerName)
    {
        auto containerPath = buildPath(storagePath, containerName);
        
        if (!exists(containerPath))
            throw new Exception("Container not found: " ~ containerName);
        
        ObjectInfo[] objects;
        
        foreach (DirEntry entry; dirEntries(containerPath, SpanMode.depth))
        {
            if (entry.isFile)
            {
                auto relativePath = relativePath(entry.name, containerPath);
                auto metadata = loadObjectMetadata(containerName, relativePath);
                
                objects ~= ObjectInfo(
                    relativePath,
                    containerName,
                    entry.size,
                    metadata.contentType,
                    metadata.createdAt,
                    metadata.lastModified,
                    metadata.etag
                );
            }
        }
        
        return objects;
    }

    ObjectInfo uploadObject(string containerName, string objectName, ubyte[] data, string contentType)
    {
        auto containerPath = buildPath(storagePath, containerName);
        
        if (!exists(containerPath))
            throw new Exception("Container not found: " ~ containerName);
        
        validateName(objectName);
        
        auto objectPath = buildPath(containerPath, objectName);
        auto objectDir = dirName(objectPath);
        
        if (!exists(objectDir))
            mkdirRecurse(objectDir);
        
        // Write data
        std.file.write(objectPath, data);
        
        // Create metadata
        auto now = Clock.currTime().toISOExtString();
        auto etag = md5Of(data).toHexString().to!string;
        
        auto metadata = ObjectMetadata(
            objectName,
            containerName,
            data.length,
            contentType,
            now,
            now,
            etag,
            null
        );
        
        saveObjectMetadata(containerName, objectName, metadata);
        
        logInfo("Uploaded object: %s/%s (%d bytes)", containerName, objectName, data.length);
        
        return ObjectInfo(
            objectName,
            containerName,
            data.length,
            contentType,
            now,
            now,
            etag
        );
    }

    ObjectData downloadObject(string containerName, string objectName)
    {
        auto containerPath = buildPath(storagePath, containerName);
        auto objectPath = buildPath(containerPath, objectName);
        
        if (!exists(objectPath))
            throw new Exception("Object not found: " ~ objectName);
        
        auto metadata = loadObjectMetadata(containerName, objectName);
        auto data = cast(ubyte[])std.file.read(objectPath);
        
        logInfo("Downloaded object: %s/%s (%d bytes)", containerName, objectName, data.length);
        
        return ObjectData(data, metadata.contentType);
    }

    void deleteObject(string containerName, string objectName)
    {
        auto containerPath = buildPath(storagePath, containerName);
        auto objectPath = buildPath(containerPath, objectName);
        
        if (!exists(objectPath))
            throw new Exception("Object not found: " ~ objectName);
        
        remove(objectPath);
        
        // Delete metadata
        auto metadataFile = buildPath(metadataPath, "objects", containerName, objectName ~ ".json");
        if (exists(metadataFile))
            remove(metadataFile);
        
        logInfo("Deleted object: %s/%s", containerName, objectName);
    }

    ObjectMetadata getObjectMetadata(string containerName, string objectName)
    {
        auto containerPath = buildPath(storagePath, containerName);
        auto objectPath = buildPath(containerPath, objectName);
        
        if (!exists(objectPath))
            throw new Exception("Object not found: " ~ objectName);
        
        return loadObjectMetadata(containerName, objectName);
    }

    // Service Key operations
    ServiceKey createServiceKey(string containerName, string keyName)
    {
        auto containerPath = buildPath(storagePath, containerName);
        
        if (!exists(containerPath))
            throw new Exception("Container not found: " ~ containerName);
        
        validateName(keyName);
        
        // Generate access token
        auto accessToken = randomUUID().toString();
        
        auto serviceKey = ServiceKey(
            keyName,
            containerName,
            accessToken,
            "http://objectstore-service/api/v1",
            Clock.currTime().toISOExtString()
        );
        
        saveServiceKey(containerName, keyName, serviceKey);
        
        logInfo("Created service key: %s for container: %s", keyName, containerName);
        
        return serviceKey;
    }

    ServiceKey getServiceKey(string containerName, string keyName)
    {
        return loadServiceKey(containerName, keyName);
    }

    void deleteServiceKey(string containerName, string keyName)
    {
        auto keyFile = buildPath(metadataPath, "keys", containerName, keyName ~ ".json");
        
        if (!exists(keyFile))
            throw new Exception("Service key not found: " ~ keyName);
        
        remove(keyFile);
        
        logInfo("Deleted service key: %s for container: %s", keyName, containerName);
    }

    // Private helper methods
    private void validateName(string name)
    {
        import std.regex;
        
        if (name.length == 0 || name.length > 255)
            throw new Exception("Name must be between 1 and 255 characters");
        
        // Allow alphanumeric, hyphens, underscores, and forward slashes
        auto validPattern = regex(r"^[a-zA-Z0-9\-_/\.]+$");
        if (!matchFirst(name, validPattern))
            throw new Exception("Name contains invalid characters");
    }

    private void saveContainerMetadata(string containerName, ContainerMetadata metadata)
    {
        auto metadataFile = buildPath(metadataPath, containerName ~ ".json");
        auto json = metadata.toJson();
        std.file.write(metadataFile, json.toPrettyString());
    }

    private ContainerMetadata loadContainerMetadata(string containerName)
    {
        auto metadataFile = buildPath(metadataPath, containerName ~ ".json");
        
        if (!exists(metadataFile))
        {
            // Return default metadata if not found
            return ContainerMetadata(
                containerName,
                buildPath(storagePath, containerName),
                Clock.currTime().toISOExtString(),
                null
            );
        }
        
        auto jsonStr = readText(metadataFile);
        auto json = parseJSON(jsonStr);
        
        string[string] customMetadata;
        if ("customMetadata" in json.object)
        {
            foreach (key, value; json["customMetadata"].object)
            {
                customMetadata[key] = value.str;
            }
        }
        
        return ContainerMetadata(
            json["name"].str,
            json["path"].str,
            json["createdAt"].str,
            customMetadata
        );
    }

    private void saveObjectMetadata(string containerName, string objectName, ObjectMetadata metadata)
    {
        auto metadataDir = buildPath(metadataPath, "objects", containerName);
        if (!exists(metadataDir))
            mkdirRecurse(metadataDir);
        
        auto metadataFile = buildPath(metadataDir, objectName ~ ".json");
        auto metadataFileDir = dirName(metadataFile);
        
        if (!exists(metadataFileDir))
            mkdirRecurse(metadataFileDir);
        
        auto json = metadata.toJson();
        std.file.write(metadataFile, json.toPrettyString());
    }

    private ObjectMetadata loadObjectMetadata(string containerName, string objectName)
    {
        auto metadataFile = buildPath(metadataPath, "objects", containerName, objectName ~ ".json");
        
        if (!exists(metadataFile))
        {
            // Return default metadata if not found
            auto now = Clock.currTime().toISOExtString();
            return ObjectMetadata(
                objectName,
                containerName,
                0,
                "application/octet-stream",
                now,
                now,
                "",
                null
            );
        }
        
        auto jsonStr = readText(metadataFile);
        auto json = parseJSON(jsonStr);
        
        string[string] customMetadata;
        if ("customMetadata" in json.object)
        {
            foreach (key, value; json["customMetadata"].object)
            {
                customMetadata[key] = value.str;
            }
        }
        
        return ObjectMetadata(
            json["name"].str,
            json["containerName"].str,
            json["size"].integer.to!ulong,
            json["contentType"].str,
            json["createdAt"].str,
            json["lastModified"].str,
            json["etag"].str,
            customMetadata
        );
    }

    private void saveServiceKey(string containerName, string keyName, ServiceKey key)
    {
        auto keyDir = buildPath(metadataPath, "keys", containerName);
        if (!exists(keyDir))
            mkdirRecurse(keyDir);
        
        auto keyFile = buildPath(keyDir, keyName ~ ".json");
        auto json = key.toJson();
        std.file.write(keyFile, json.toPrettyString());
    }

    private ServiceKey loadServiceKey(string containerName, string keyName)
    {
        auto keyFile = buildPath(metadataPath, "keys", containerName, keyName ~ ".json");
        
        if (!exists(keyFile))
            throw new Exception("Service key not found: " ~ keyName);
        
        auto jsonStr = readText(keyFile);
        auto json = parseJSON(jsonStr);
        
        return ServiceKey(
            json["keyName"].str,
            json["containerName"].str,
            json["accessToken"].str,
            json["endpoint"].str,
            json["createdAt"].str
        );
    }
}
