extends Node

func create_quadtree(bounds, capacity, max_level, level = 0, parent = null) -> _QuadTree:
	"""
	Creates a quadtree and initializes it for you.
	This function is being used in the QuadTree class itself.
	"""
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
		"""
		Adds a new body into the QuadTree.
		"""
		if body.has_meta("_qt"): return null  # object already in tree
		
		if !_is_leaf:
			# add to child if not current obj is leaf.
			var child = _get_child(body.get_transformed_aabb())
			if child:
				child.add(body)
		
		body.set_meta("_qt", self)
		# add the object into the tree
		_objects.push_back(body)
				
		if _is_leaf and _level < _max_level and _objects.size() >= _capacity:
			# subdivide if necessary
			_subdivide()
			# update the body's quadtree.
			update(body)
		return body
	
	func remove(body: VisualInstance) -> Object:
		"""
		Removes the pre-existing body from the QuadTree
		"""
		if !body.has_meta("_qt"): return null  # body not in tree
		
		# get the QuadTreeNode
		var qt_node = MetaStaticFuncs.get_meta_or_null(body, "_qt")
		if qt_node != self: # check if is different from the current level
			return qt_node.remove(body)  # call the qt_node's remove method
		
		# if the object is same, then remove it directly
		_objects.erase(body)
		# remove the `_qt` node because it's no longer in quad tree
		MetaStaticFuncs.remove_meta_with_check(body, "_qt")
		
		return body
			
	
	func update(body: VisualInstance) -> Object:
		"""
		Updates the body. A method for moving objects.
		"""
		if !remove(body): return null  # something went wrong while removing the object
		
		if _parent != null and !_bounds.encloses(body.get_transformed_aabb()): # QuadTreeNode is not root, add it here.
			return _parent.add(body)
		
		if !_is_leaf:  # QuadTreeNode is not leaf
			# get the child
			var child = _get_child(body.get_transformed_aabb())
			if child:
				# add it
				return child.add(body)
		
		return add(body)
	
	func _subdivide():
		"""
		:PrivateMeth
		
		Subdivides the quad tree into 4 childs.
		"""
		# subdivide the quadtree into 4 childs and initialize them
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
			
			# initialize the node and set the child
			_children[i] = _node.create_quadtree(AABB(position, _center), _capacity, _max_level, _level+1, self)
		
		_is_leaf = false # change is_leaf to false, because it has childs now.
			
	
	func clear():
		"""
		Clears the QuadTree.
		"""
		# recursively remove all the objects
		if !_objects.empty():
			for object in _objects:
				MetaStaticFuncs.remove_meta_with_check(object, "_qt")
			_objects.clear()

		if !_is_leaf:  # if the self is not leaf
			for child in _children:
				child.clear()  # clear all it's children
			_is_leaf = true
	
	func query(bound: AABB):
		"""
		Queries the QuadTree and returns the objects that exists within the bounds passed.
		"""
		# clear the old objects
		_found_objects.clear()
		for object in _objects:
			var transformed_aabb = object.get_transformed_aabb()
			if transformed_aabb != bound and transformed_aabb.intersects(bound):  # check if the object in the bounds and it's not bound
				# add the object into _found_objects
				_found_objects.push_back(object)
		if !_is_leaf:
			var child = _get_child(bound)
			if child:
				# query the child to find other objects
				child.query(bound)
				_found_objects += child._found_objects  # add them into the main list
		
			else:
				for leaf in _children:
					# check if the leaf intersects with the bound
					if leaf._bounds.intersects(bound):
						leaf.query(bound)  # query the leaf for the objects
						_found_objects += leaf._found_objects  # add them into the main list
		return _found_objects
		
	
	func _unsubdivide():
		"""
		:PrivateMeth
		
		Discards all the leafs and childs with no objects.
		"""
		if (!_objects.empty()): return null  # skip if objects is not empty
		
		if (!_is_leaf):
			for child in _children:
				if !child._is_leaf or !child._objects.empty(): return null  # skip if the child is not leaf or if there're objects in the child.
		
		clear()  # clear the level
		if _parent:
			_parent._unsubdivide()  # unsubdivide the parent if needed.
	
	func _get_child(body_bounds: AABB):
		"""
		:PrivateMeth
		
		Gets the child that incorporates itself in the body_bounds passed.
		"""
		if body_bounds.end.z < _bounds.end.z / 2:
			if body_bounds.end.x < _bounds.end.x / 2:
				return _children[1]  # top left
			elif body_bounds.position.x > _bounds.end.x / 2:
				return _children[0]  # top right
		elif body_bounds.position.z > _bounds.end.z / 2:
			if body_bounds.end.x < _bounds.end.x / 2:
				return _children[2]  # bottom left
			elif body_bounds.position.x > _bounds.end.x / 2:
				return _children[3]  # bottom right
		return null # cannot contain boundary -- too large
		
	
	func _create_rect_lines(points):
		"""
		:PrivateMeth
		
		Creates the lines that shows the subdivided quadtree.
		"""
		
		# recursively call _create_rect_lines to create dividing lines.
		for child in _children:
			if child:
				child._create_rect_lines(points)
		
		# create the points
		var p1 = Vector3(_bounds.position.x, _bounds.position.z, 1)
		var p2 = Vector3(p1.x + _bounds.size.x, p1.y, 1)
		var p3 = Vector3(p1.x + _bounds.size.x, p1.y + _bounds.size.z, 1)
		var p4 = Vector3(p1.x, p1.y + _bounds.size.z, 1)
		# append them into points array
		points.append(p1)
		points.append(p2)

		points.append(p2)
		points.append(p3)

		points.append(p3)
		points.append(p4)

		points.append(p4)
		points.append(p1)
	
	func draw(drawer: ImmediateGeometry, material: Material):
		"""
		Initializes drawing stuff for you, you can use `_draw` method if you want to have special initialization.
		"""
		drawer.set_material_override(material)
		drawer.begin(Mesh.PRIMITIVE_LINES)
		_draw(drawer)
		drawer.end()
		
	func _draw(drawer: ImmediateGeometry):
		"""
		:PrivateMeth
		
		Draws the visuals of QuadTree, tweak it however you want.
		"""
		
		# recursively call _draw to draw objects in different subnodes.
		for child in _children:
			if not _is_leaf:
				print(child)
				child._draw(drawer)
		var points = []
		# initialize the points
		_create_rect_lines(points)
		
		# draw them into the node.
		for point in points:
			drawer.add_vertex(Vector3(point.x, 1, point.y)) # change it to x and y axis if needed.
		
		# draw the bodies
		for body in _objects:
			# convert aabb to rect for easier usage
			var rect = _convert_aabb_to_rect(body.get_transformed_aabb())
			
			# get all 4 points
			var Bpoint = Vector3(rect.end.x, 1, rect.position.y)
			var Dpoint = Vector3(rect.position.x, 1,  rect.end.y)
			var Apoint = Vector3(rect.position.x, 1, rect.position.y)
			var Cpoint = Vector3(rect.end.x, 1, rect.end.y)
			
			# add them here
			drawer.add_vertex(Apoint)
			drawer.add_vertex(Bpoint)
			drawer.add_vertex(Bpoint)
			drawer.add_vertex(Cpoint)
			drawer.add_vertex(Cpoint)
			drawer.add_vertex(Dpoint)
			drawer.add_vertex(Dpoint)
			drawer.add_vertex(Apoint)
		
	func _convert_aabb_to_rect(transformed_aabb: AABB):
		"""
		:PrivateMeth
		
		Converts a AABB to Rect2
		"""
		return Rect2(Vector2(transformed_aabb.position.x, transformed_aabb.position.z), Vector2(transformed_aabb.size.x, transformed_aabb.size.z))  # assumed as XZ plane
	

# driver code
func _ready() -> void:
	# create quadtree
	var root_qt_node = self.create_quadtree(AABB(Vector3(-25, 0, -25), Vector3(50, 0, 50)), 5, 5)
	# create 25 objects to test out quad tree
	for i in range(25):
		# create new mesh instance
		var new_mesh = MeshInstance.new()
		# create a new cube mesh
		var cube_mesh = CubeMesh.new()
		# set it's size random from 2, 4 
		cube_mesh.size = Vector3(rand_range(2, 4), 0, rand_range(2, 4))
		new_mesh.mesh = cube_mesh
		# set the position random from -25 to 25 -- size of the terrain
		new_mesh.set_translation(Vector3(rand_range(-25, 25), 0, rand_range(-25, 25)))
		add_child(new_mesh)
		# add it into the quad tree
		root_qt_node.add(new_mesh)
	
	# test query -- create a new sphere mesh and set it's radius to 5
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 5
	# create a new meshinstance and set it's translation to `Vector3(4, 0, 4)`
	var new_mesh = MeshInstance.new()
	new_mesh.set_translation(Vector3(4, 0, 4))
	# hide it, because we don't want it to be shown.
	new_mesh.hide()
	# set the mesh and add it into the scene
	new_mesh.mesh = sphere_mesh
	add_child(new_mesh)
	# query the QuadTree with the sphere mesh's Tranformed AABB
	var returned_objects = root_qt_node.query(new_mesh.get_transformed_aabb())
	
	# print the returned objects
	print(returned_objects)


	# visualize the quad tree
	var spatial_mat = SpatialMaterial.new()
	spatial_mat.albedo_color = Color(0, 0, 0, 1)
	root_qt_node.draw(get_node("/root/Spatial/ImmediateGeometry"), spatial_mat)
	
	# remove and update are not tested please use it in your own risk.
