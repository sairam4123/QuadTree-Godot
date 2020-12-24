#include "QuadTree.h"

//** AABB **//
AABB::AABB(const double &l, const double &t, const double &r, const double &b) :
	left(l),
	top(t),
	right(r),
	bottom(b) {
}
bool AABB::within(const AABB &bound) const {
	return left > bound.left && bottom > bound.bottom
		&& right < bound.right && top < bound.top;
}
bool AABB::intersects(const AABB &bound) const {
	if (bound.right <= left) return false;
	if (bound.left >= right) return false;
	if (bound.top <= bottom) return false;
	if (bound.bottom >= top) return false;
	return true; // intersection
}

//** Object **//
Object::Object(const AABB &bound, void *data):
	_bound(bound), 
	_data(data) {
};
void Object::setData(void *data) {
	_data = data;
}
void *Object::getData() const { 
	return _data;
}

//** QuadTree **//
QuadTree::QuadTree(const AABB &bound, const unsigned &capacity, const unsigned &maxLevel, 
	const unsigned &level, QuadTree *parent):
	_capacity(capacity),
	_maxLevel(maxLevel),
	_level(level), 
	_parent(parent),
	_centerX((bound.left + bound.right) * 0.5f),
	_centerY((bound.bottom + bound.top) * 0.5f),
	_bound(bound) {
}

// Inserts an object into this quadtree
bool QuadTree::insert(Object *obj) {
	// Item already exists
	if (obj->_qt != nullptr)
		return false;

	// insert object at the lowest level
	if (!_isLeaf) {
		if (QuadTree *child = getChild(obj->_bound))
			return child->insert(obj);
	}
	_objects.push_back(obj);
	obj->_qt = this; // used for quick search by quadtree

	// Subdivide if required
	if (_isLeaf && _level < _maxLevel && _objects.size() >= _capacity) {
		subdivide();

		// Re-insert objects into new quadrant
		for (unsigned i = 0; i < _objects.size();) {
			Object *object = _objects[i];
			if (QuadTree *child = getChild(object->_bound)) {
				_objects.erase(_objects.begin() + i);
				object->_qt = nullptr;
				child->insert(object);
			}
			else ++i;
		}
	}
	return true;
}

// Removes an object from this quadtree
bool QuadTree::remove(Object *obj) {
	if (obj->_qt == nullptr)
		return false;
	if (obj->_qt != this)
		return obj->_qt->remove(obj);

	_objects.erase(std::find(_objects.begin(), _objects.end(), obj));
	obj->_qt = nullptr;
	discardEmptyBuckets(this);
	return true;
}

// Removes and re-inserts object into quadtree (for objects that move)
void QuadTree::update(Object *obj) {
	QuadTree *node = obj->_qt;
	if (node->_parent == nullptr || obj->_bound.within(node->_bound))
		return;
	// Re-insert object at the highest level
	node->remove(obj);
	do {
		node = node->_parent;
		if (obj->_bound.within(node->_bound))
			break;
	} while (node->_parent != nullptr);
	node->insert(obj);
}

// Checks if object exists in this quadtree
bool QuadTree::contains(Object *obj) const {
	if (obj->_qt == nullptr)
		return false;
	if (obj->_qt != this)
		return obj->_qt->contains(obj);

	return std::find(_objects.begin(), _objects.end(), obj) != _objects.end();
}

// Searches quadtree for objects within the provided boundary and returns them in callback
void QuadTree::search(const AABB &bound, const std::function<void(Object*)> &callback) const {
	// Search children first
	if (!_isLeaf) {
		if (QuadTree *child = getChild(bound)) {
			child->search(bound, callback);
		} else {
			for (auto&& node : _children) {
				if (node->_bound.intersects(bound))
					node->search(bound, callback);
			}
		}
	}
	// Now search objects
	for (auto&& obj : _objects) {
		if (obj->_bound.intersects(bound))
			callback(obj);
	}
}

// Searches quadtree for objects within the provided boundary and adds them to provided vector
void QuadTree::query(const AABB &bound, std::vector<Object*> &returnObjects) const {
	search(bound, [&returnObjects](Object *obj) {
		returnObjects.push_back(obj);
	});
}

// Checks if any object exists in the specified bounds (with optional filter)
bool QuadTree::any(const AABB &bound, const std::function<bool(Object*)> &condition) const {
	bool found = false;
	search(bound, [&condition, &found](Object *obj) {
		if (condition == nullptr || condition(obj)) {
			found = true;
			return;
		}
	});
	return found;
}

// Returns total children count for this quadtree
unsigned QuadTree::getTotalChildren() const {
	unsigned count = 0;
	if (!_isLeaf) {
		for (auto&& child : _children)
			count += child->getTotalChildren();
	}
	return (_isLeaf? 0 : 4) + count;
}

// Returns total object count for this quadtree
unsigned QuadTree::getTotalObjects() const {
	unsigned count = 0;
	if (!_isLeaf) {
		for (auto&& node : _children)
			count += node->getTotalObjects();
	}
	return _objects.size() + count;
}

// Removes all objects and children from this quadtree
void QuadTree::clear() {
	if (!_objects.empty()) {
		for (auto&& obj : _objects)
			remove(obj);
		_objects.clear();
	}
	if (!_isLeaf) {
		delete _children[0];
		delete _children[1];
		delete _children[2];
		delete _children[3];
		_isLeaf = true;
	}
}

// Subdivides into four quadrants
void QuadTree::subdivide() {
	// Bottom right
	_children[0] = new QuadTree(
		{ _centerX, _centerY, _bound.right, _bound.bottom },
		_capacity, _maxLevel, _level + 1, this
	);
	// Bottom left
	_children[1] = new QuadTree(
		{ _bound.left, _centerY, _centerX, _bound.bottom },
		_capacity, _maxLevel, _level + 1, this
	);
	// Top left
	_children[2] = new QuadTree(
		{ _bound.left, _bound.top, _centerX, _centerY },
		_capacity, _maxLevel, _level + 1, this
	);
	// Top right
	_children[3] = new QuadTree(
		{ _centerX, _bound.top, _bound.right, _centerY },
		_capacity, _maxLevel, _level + 1, this
	);
	_isLeaf = false;
}

// Discards buckets if all children are leaves and contain no objects
void QuadTree::discardEmptyBuckets(QuadTree *node) {
	if (!node->_objects.empty())
		return;
	if (!node->_isLeaf) {
		for (auto &&child : node->_children) {
			if (!child->_isLeaf || !child->_objects.empty())
				return;
		}
		node->clear();
	}
	if (node->_parent != nullptr)
		discardEmptyBuckets(node->_parent);
}

// Returns child/quadrant that the provided boundary is in
QuadTree *QuadTree::getChild(const AABB &bound) const {
	bool bottom = bound.bottom > _centerY;
	bool left   = bound.left < _centerX;
	bool top    = !bottom && bound.top < _centerY;
	if (left && bound.right < _centerX) {
		if (top)    return _children[1]; // top left
		if (bottom) return _children[2]; // bottom left
	}
	else if (!left) {
		if (top)    return _children[0]; // top right
		if (bottom) return _children[3]; // bottom right
	}
	return nullptr;
}

QuadTree::~QuadTree() {
	clear();
}
