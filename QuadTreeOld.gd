#extends Node
#
#var counter = 0
#class _QuadTree:
#
#	const MAX_OBJECTS = 10
#	const MAX_LEVELS = 10
#
#	var _level: int
#	var _objects: Array
#	var _bounds: AABB
#	var _childs = [null, null, null, null]
#	var _parent = null
#
#	func _init(bounds: AABB, level = 0, parent = null):
#		self._bounds = bounds
#		self._objects = []
#		self._level = level
#		self._parent = parent
#
#	func clear():
#		self._objects.clear()
#		var counter = 0
#		for node in self._childs.duplicate():
#			if node:
#				node.clear()
#				_childs[counter] = null
#			counter += 1
#
#	func _split(obj):
#		var middle = _bounds.size / 2
#
#		var aBounds = AABB(_bounds.position, middle)
#		var bBounds = AABB(Vector3(_bounds.position.x + middle.x, _bounds.position.y, _bounds.position.z), middle)
#		var cBounds = AABB(Vector3(_bounds.position.x + middle.x, _bounds.position.y, _bounds.position.z + middle.z), middle)
#		var dBounds = AABB(Vector3(_bounds.position.x, _bounds.position.y, _bounds.position.z + middle.z), middle)
#
#		prints(aBounds, "|", bBounds, "|",  cBounds, "|", dBounds)
#		prints(aBounds.end, "|", bBounds.end, "|",  cBounds.end, "|", dBounds.end)
#		obj.counter += 1
#		_childs[0] = _QuadTree.new(bBounds, _level+1, self)
#		_childs[1] = _QuadTree.new(aBounds, _level+1, self)
#		_childs[2] = _QuadTree.new(dBounds, _level+1, self)
#		_childs[3] = _QuadTree.new(cBounds, _level+1, self)
#
#		for object in _objects:
#			var quadrant = get_quadrant(object.get_translation())
#			if quadrant:
#				quadrant.add(object, obj)
#		_objects.clear()
#
#	func add(body, obj):
#		if _childs[0]:
#			var quadrant = get_quadrant(body.get_translation())
#			if quadrant:
#				quadrant.add(body, obj)
#				return
#		_objects.append(body)
#
#		if _objects.size() > MAX_OBJECTS and _level < MAX_LEVELS:
#			if not _childs[0]:
#				_split(obj)
#
#
#
#
#	func remove(body):
#		if _childs[0]:
#			var quadrant = get_quadrant(body.get_translation())
#			if quadrant:
#				quadrant.remove(body)
#				return
#		_objects.erase(body)
#		var object_count = 0
#		for child in _childs:
#			if child:
#				object_count += child._objects.size()
#		if object_count < MAX_OBJECTS and _childs[0]:
#			_unsplit()
#
#	func _unsplit():
#		print("Unsplit called")
#
#	func get_objects_in_range(range_: AABB):
#		var result = []
#		_get_objects_in_range(range_, result)
#		return result
#
#	func _get_objects_in_range(range_: AABB, result: Array):
#		if !_childs[0]:
#			for object in _objects:
#				result.append(object)
#		else:
#			for quadrant in _childs:
#				if quadrant._bounds.intersects(range_):
#					quadrant._get_objects_in_range(range_, result)
#
#
#	func get_quadrant(pos: Vector3):
#		var center = _bounds.end / 2
#		if pos.z < center.x:
#			if pos.x < center.z:
#				return _childs[1]
#			elif pos.x > center.z:
#				return _childs[2]
#		elif pos.z > center.x:
#			if pos.x < center.z:
#				return _childs[0]
#			elif pos.x > center.z:
#				return _childs[3]
#		else:
#			return null
#
#
#
#func _ready():
#	var quad_tree = self._QuadTree.new(AABB(Vector3(-25, 0, -25), Vector3(50, 0, 50)))
#	var bodies = []
#	for i in range(12):
#		var spatial = Spatial.new()
#		spatial.set_translation(Vector3(i, 15, i+1))
#		quad_tree.add(spatial, self)
#		bodies.append(spatial)
#
#	for i in range(12):
#		quad_tree.remove(bodies[i])
#
#	prints("\n\n\n\n", counter)
	
## extends Node
#
#class QuadTree:
#	var _bounds: AABB
#	var _capacity: int
#	var _max_level: int
#	var _level: int
#	var _parent = null
#	var _children = []
#	var _objects = []
#	var _is_leaf: bool = true
#	var _center: Vector3
#
#	func _init(bounds, capacity, max_level, level, parent = null) -> void:
#		self._bounds = bounds
#		self._capacity = capacity
#		self._max_level = max_level
#		self._level = level
#		self._parent = parent
#		self._center = self._bounds.size / 2
#
#	func add(body: VisualInstance):
#		# item already exists
#		if body.has_meta("_qt"):
#			return
#		if !self._is_leaf:
#			var child = _get_child(body.get_aabb())
#			if child:
#				child.add(body)
#
#		_objects.append(body)
#		body.set_meta("_qt", self)
#
#		if self._is_leaf and _level < _max_level and _objects.size() >= _capacity:
#			_subdivide()
#
#			for object in _objects:
#				var child = _get_child(object.get_aabb())
#				if child:
#					_objects.erase(child)
#					if object.has_meta("_qt"):
#						object.remove_meta("_qt")
#					child.add(object)
#
#
#	func remove(body: VisualInstance):
#		# item doesn't exist
#		if !body.has_meta("_qt"):
#			return
#		if body.has_meta("_qt"):
#			var qt_node = body.get_meta("_qt")
#			if qt_node != self:
#				qt_node.remove(body)
#
#		_objects.erase(body)
#		if body.has_meta("_qt"):
#			body.remove_meta("_qt")
#		_unsubdivide()
#
#	func update(body: VisualInstance):
#		# item doesn't exist
#		if !body.has_meta("_qt"):
#			return
#
#		if body.has_meta("_qt"):
#			var qt_node = body.get_meta("_qt")
#			if qt_node.parent == null or qt_node._bounds.encloses(body.get_transformed_aabb()):
#				return
#
#			qt_node.remove(body)
#			while qt_node._parent != null:
#				qt_node = qt_node._parent
#
#				if qt_node._bounds.encloses(body.get_aabb()):
#					break
#			qt_node.add(body)
#
#
#
#	func contains(body):
#		pass
#
#	func search():
#		pass
#
#	func query():
#		pass
#
#	func get_total_children():
#		pass
#
#	func get_total_objects():
#		pass
#
#	func clear():
#		pass
#
#	func _subdivide():
#		pass
#
#	func _unsubdivide():
#		pass
#
#	func _get_child(bounds: AABB):
#		pass
#
