module objectstore.models;

import std.datetime;
import vibe.data.json;

struct Container
{
    string name;
    string createdAt;
    ulong objectCount;
    ulong totalSize;

    Json toJson() const
    {
        return Json([
            "name": Json(name),
            "createdAt": Json(createdAt),
            "objectCount": Json(objectCount),
            "totalSize": Json(totalSize)
        ]);
    }
}

struct ObjectInfo
{
    string name;
    string containerName;
    ulong size;
    string contentType;
    string createdAt;
    string lastModified;
    string etag;

    Json toJson() const
    {
        return Json([
            "name": Json(name),
            "containerName": Json(containerName),
            "size": Json(size),
            "contentType": Json(contentType),
            "createdAt": Json(createdAt),
            "lastModified": Json(lastModified),
            "etag": Json(etag)
        ]);
    }
}

struct ObjectData
{
    ubyte[] data;
    string contentType;
}

struct ServiceKey
{
    string keyName;
    string containerName;
    string accessToken;
    string endpoint;
    string createdAt;

    Json toJson() const
    {
        return Json([
            "keyName": Json(keyName),
            "containerName": Json(containerName),
            "accessToken": Json(accessToken),
            "endpoint": Json(endpoint),
            "createdAt": Json(createdAt)
        ]);
    }
}

struct ContainerMetadata
{
    string name;
    string path;
    string createdAt;
    string[string] customMetadata;

    Json toJson() const
    {
        auto custom = Json.emptyObject;
        foreach (key, value; customMetadata)
        {
            custom[key] = Json(value);
        }

        return Json([
            "name": Json(name),
            "path": Json(path),
            "createdAt": Json(createdAt),
            "customMetadata": custom
        ]);
    }
}

struct ObjectMetadata
{
    string name;
    string containerName;
    ulong size;
    string contentType;
    string createdAt;
    string lastModified;
    string etag;
    string[string] customMetadata;

    Json toJson() const
    {
        auto custom = Json.emptyObject;
        foreach (key, value; customMetadata)
        {
            custom[key] = Json(value);
        }

        return Json([
            "name": Json(name),
            "containerName": Json(containerName),
            "size": Json(size),
            "contentType": Json(contentType),
            "createdAt": Json(createdAt),
            "lastModified": Json(lastModified),
            "etag": Json(etag),
            "customMetadata": custom
        ]);
    }
}
