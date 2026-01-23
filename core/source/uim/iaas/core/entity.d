module uim.iaas.core.entity;

import uim.iaas.core;

@safe:

class IaasEntity {
  this() {
  }

  // Properties
  protected string _id;
  @property string id() {
    return _id;
  }

  @property void id(string value) {
    _id = value;
  }

  protected long _createdAt;
  @property long createdAt() {
    return _createdAt;
  }

  @property void createdAt(long value) {
    _createdAt = value;
  }

  protected long _updatedAt;
  @property long updatedAt() {
    return _updatedAt;
  }

  @property void updatedAt(long value) {
    _updatedAt = value;
  }

  protected string[string] _metadata;
  @property string[string] metadata() {
    return _metadata;
  }

  @property void metadata(string[string] value) {
    _metadata = value;
  }

  @property string metadata(string key) {
    return _metadata[key];
  }

  @property void metadata(string key, string value) {
    _metadata[key] = value;
  }

  Json toJson() {
    return Json([
      "id": _id.toJson,
      "createdAt": _createdAt.toJson,
      "updatedAt": _updatedAt.toJson,
      "metadata": _metadata.toJson
    ]);
  }
}
