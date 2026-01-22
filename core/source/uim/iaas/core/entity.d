module uim.iaas.core.entity;

import uim.iaas.core;

@safe:

class UIMEntity {
    this() {
    }

    // Properties
    protected string _id;
    @property string id() { return _id; }
    @property void id(string value) { _id = value; }

    protected long _createdAt;
    @property long createdAt() { return _createdAt; }
    @property void createdAt(long value) { _createdAt = value; }

    protected long _updatedAt;
    @property long updatedAt() { return _updatedAt; }
    @property void updatedAt(long value) { _updatedAt = value; }
}
