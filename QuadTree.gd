extends Node

func create_quadtree(bounds, capacity, max_level, level = 0, parent = null) -> _QuadTree:
	return self._QuadTree.new(bounds, capacity, max_level, level, parent, self)
	
class _QuadTree:
	var _bounds: AABB
	var _capacity: int
	var _max_level: int
	var _level: int
	var _parent = null
	var _children = []
	var _objects = []
	var _found_objects = []
	var _is_leaf: bool = true
	var _center: Vector3
	var _node: Node = null

	func _init(bounds, capacity, max_level, level = 0, parent = null, node = null) -> void:
		self._bounds = bounds
		self._capacity = capacity
		self._max_level = max_level 
		self._level = level
		self._parent = parent
		self._center = self._bounds.size / 2
		self._children.resize(4)
		self._node = node
	
	func add(body: VisualInstance) -> Object:
		if body.has_meta("_qt"): return null
		
		if !_is_leaf:
			var child = _get_child(body.get_transformed_aabb())
			if child:
				child.add(body)
		
		body.set_meta("_qt", self)
		_objects.push_back(body)
				
		if _is_leaf and _level < _max_level and _objects.size() >= _capacity:
			print("subdividing")
			_subdivide()
			update(body)
		return body
	
	func remove(body: VisualInstance) -> Object:
		if !body.has_meta("_qt"): return null
		
		var qt_node = MetaStaticFuncs.get_meta_or_null(body, "_qt")
		if qt_node != self:
			return qt_node.remove(body)
		
		_objects.erase(body)
		MetaStaticFuncs.remove_meta_with_check(body, "_qt")
		
		return body
			
	
	func update(body: VisualInstance):
		if !remove(body): return null
		
		if _parent != null and !_bounds.encloses(body.get_transformed_aabb()):
			return _parent.add(body)
		
		if !_is_leaf:
			var child = _get_child(body.get_transformed_aabb())
			if child:
				return child.add(body)
		
		return add(body)
	
	func _subdivide():
#		print("subdivide started")
		var position
		for i in range(4):
			match i:
				0: 
					position = Vector3(_bounds.position.x + _center.x, _bounds.position.y, _bounds.position.z)
				1: 
					position = Vector3(_bounds.position.x, _bounds.position.y, _bounds.position.z)
				2: 
					position = Vector3(_bounds.position.x, _bounds.position.y, _bounds.position.z + _center.z)
				3: 
					position = Vector3(_bounds.position.x + _center.x, _bounds.position.y, _bounds.position.z + _center.z)
#			print(i)
			_children[i] = _node.create_quadtree(AABB(position, _center), _capacity, _max_level, _level+1, self)
		
		_is_leaf = false
			
	
	func clear():
		if !_objects.empty():
			for object in _objects:
				MetaStaticFuncs.remove_meta_with_check(object, "_qt")
			_objects.clear()
		if !_is_leaf:
			for child in _children:
				child.clear()
			_is_leaf = true
	
	func query(bound: AABB):
		_found_objects.clear()
		for object in _objects:
			var transformed_aabb = object.get_transformed_aabb()
			if transformed_aabb != bound and transformed_aabb.intersects(bound):
				_found_objects.push_back(object)
		if !_is_leaf:
			var child = _get_child(bound)
			if child:
				child.query(bound)
				_found_objects += child._found_objects
		
			else:
				for leaf in _children:
					print(_children)
					if leaf._bounds.intersects(bound):
						leaf.query(bound)
						_found_objects += leaf._found_objects
		return _found_objects
		
	
	func _unsubdivide():
		if (!_objects.empty()): return null
		
		if (!_is_leaf):
			for child in _children:
				if !child._is_leaf or !child._objects.empty(): return null
		
		clear()
		if _parent:
			_parent._unsubdivide()
	
	func _get_child(body_bounds: AABB):
		if body_bounds.end.z < _bounds.end.z / 2:
			if body_bounds.end.x < _bounds.end.x / 2:
				return _children[1]
			elif body_bounds.position.x > _bounds.end.x / 2:
				return _children[0]
		elif body_bounds.position.z > _bounds.end.z / 2:
			if body_bounds.end.x < _bounds.end.x / 2:
				return _children[2]
			elif body_bounds.position.x > _bounds.end.x / 2:
				return _children[3]
		
	
	func _get_rect_lines(points):
		for child in _children:
			child._get_rect_lines(points)

		var p1 = Vector3(_bounds.position.x, _bounds.position.z, 1)
		var p2 = Vector3(p1.x + _bounds.size.x, p1.y, 1)
		var p3 = Vector3(p1.x + _bounds.size.x, p1.y + _bounds.size.z, 1)
		var p4 = Vector3(p1.x, p1.y + _bounds.size.z, 1)
		points.append(p1)
		points.append(p2)

		points.append(p2)
		points.append(p3)

		points.append(p3)
		points.append(p4)

		points.append(p4)
		points.append(p1)
	
	func draw(drawer: ImmediateGeometry, material: Material):
		drawer.set_material_override(material)
		drawer.begin(Mesh.PRIMITIVE_LINES)
		
		var points = []
		_get_rect_lines(points)
		for point in points:
			drawer.add_vertex(Vector3(point.x, 1, point.z)) # change it to x and y axis if needed.
		
		var rect = _convert_aabb_to_rect()
		drawer
		
		
	func _convert_aabb_to_rect():
		return Rect2(Vector2(_bounds.position.x, _bounds.position.z), Vector2(_bounds.size.x, _bounds.size.z))
	

# driver code
func _ready() -> void:
	var root_qt_node = self.create_quadtree(AABB(Vector3(-25, 0, -25), Vector3(50, 0, 50)), 5, 5)
	for i in range(10):
		var new_mesh = MeshInstance.new()
		var cube_mesh = CubeMesh.new()
		cube_mesh.size = Vector3(i, i, i)
		new_mesh.mesh = cube_mesh
		new_mesh.set_translation(Vector3(i+2, 0, i+2))
		add_child(new_mesh)
		print(root_qt_node.add(new_mesh))
#		print(root_qt_node._objects)
#		print(root_qt_node._children)
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 5
	var new_mesh = MeshInstance.new()
	new_mesh.set_translation(Vector3(4, 0, 4))
	new_mesh.mesh = sphere_mesh
	add_child(new_mesh)
	print(root_qt_node.query(new_mesh.get_transformed_aabb()))
