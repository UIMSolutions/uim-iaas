/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module uim.iaas.storage.entities.bucket;

import uim.iaas.storage;

class BucketEntity : IaasEntity {
  this() {
    super();
  }

  // Name of the bucket
  protected string _name;
  @property string name() {
    return _name;
  }

  @property void name(string value) {
    _name = value;
  }

  // Tenant ID owning the bucket
  protected string _tenantId;
  @property string tenantId() {
    return _tenantId;
  }

  @property void tenantId(string value) {
    _tenantId = value;
  }

  // Region where the bucket is located
  protected string _region;
  @property string region() {
    return _region;
  }

  @property void region(string value) {
    _region = value;
  }

  // Properties specific to object storage buckets
  protected long _objectCount;
  @property long objectCount() {
    return _objectCount;
  }

  @property void objectCount(long value) {
    _objectCount = value;
  }

  // Total size in bytes
  protected long _totalSizeBytes;
  @property long totalSizeBytes() {
    return _totalSizeBytes;
  }

  @property void totalSizeBytes(long value) {
    _totalSizeBytes = value;
  }

  // Status of the bucket (e.g., active, deleted)
  protected string _status;
  @property string status() {
    return _status;
  }

  @property void status(string value) {
    _status = value;
  }
}
