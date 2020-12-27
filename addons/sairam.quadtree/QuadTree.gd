extends Spatial
class_name QuadTree


var _bounds: AABB
var _capacity: int
var _max_level: int
var _level: int
var _parent: QuadTree = null
var _children = []
var _objects = []
var _found_objects = []
var _is_leaf: bool = true
var _center: Vector3
var _material: Material
var _immediate_geo_node: ImmediateGeometry

func _init(bounds, capacity, max_level, level = 0, parent = null, material = null, immediate_geo_node = null) -> void:
	self._bounds = bounds
	self._capacity = capacity
	self._max_level = max_level 
	self._level = level
	self._parent = parent
	self._center = self._bounds.size / 2
	self._material = material
	self._immediate_geo_node = immediate_geo_node
	if immediate_geo_node:
		self._immediate_geo_node.set_material_override(material)
	_set_as_empty_leaf()

func _set_as_empty_leaf():
	self._children = []
	self._children.resize(4)
	_is_leaf = true
	
func add_body(body: VisualInstance) -> Object:
	"""
	Adds a new body into the QuadTree.
	"""
	if body.has_meta("_qt"): return null  # object already in tree
	
	if !_is_leaf:
		# add to child if not current obj is leaf.
		var child = _get_child(body.get_transformed_aabb())
		if child:
			return child.add_body(body)
	
	body.set_meta("_qt", self)
	# add the object into the tree
	_objects.push_back(body)
			
	if _is_leaf and _level < _max_level and _objects.size() >= _capacity:
		# subdivide if necessary
		_subdivide()
		# update the body's quadtree.
#		return update_body(body, false)
	return body

func remove_body(body: VisualInstance, do_unsubdivide = true) -> Object:
	"""
	Removes the pre-existing body from the QuadTree
	"""
	# print("remove body %s" % body)

	if !body.has_meta("_qt"): 
		print("no meta")
		return null  # body not in tree
	
	
	# get the QuadTreeNode
	var qt_node = MetaStaticFuncs.get_meta_or_null(body, "_qt")
	if qt_node != self and qt_node: # check if is different from the current level
		# print("remove body from child")
		return qt_node.remove_body(body, do_unsubdivide)  # call the qt_node's remove method
	
	# remove the `_qt` node because it's no longer in quad tree
	MetaStaticFuncs.remove_meta_with_check(body, "_qt")	
	# if the object is same, then remove it directly
	_objects.erase(body)
	if do_unsubdivide:
		_unsubdivide()

	_unsubdivide()
	return body
		

func update_body(body: VisualInstance, do_unsubdivide = true) -> Object:
	"""
	Updates the body. A method for moving objects.
	"""
	if !remove_body(body, do_unsubdivide): return null  # something went wrong while removing the object
	
	if _parent != null and !_bounds.encloses(body.get_transformed_aabb()): # QuadTreeNode is not root, add it here.
		return _parent.add_body(body)
	
	if !_is_leaf:  # QuadTreeNode is not leaf
		# get the child
		var child = _get_child(body.get_transformed_aabb())
		if child:
			# add it
			return child.add_body(body)
	
	return add_body(body)

func _subdivide() -> void:
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
		_children[i] = get_script().new(AABB(position, _center), _capacity, _max_level, _level+1, self)
	
	_is_leaf = false # change is_leaf to false, because it has childs now.
		

func clear() -> void:
	"""
	Clears the QuadTree.
	"""
	print("clear called")
	# recursively remove all the objects
	if !_objects.empty():
		for object in _objects:
			MetaStaticFuncs.remove_meta_with_check(object, "_qt")
		_objects.clear()

	if !_is_leaf:  # if the self is not leaf
		for child in _children:
			child.clear()  # clear all it's children
		_set_as_empty_leaf()

func query(bound: AABB) -> Array:
	"""
	Queries the QuadTree and returns the objects that exists within the bounds passed.
	
	Removes Duplicates as well.
	"""
	# clear the old objects
	_found_objects.clear()
	# query the QuadTree
	var old_found_objects = _query(bound)
	# remove duplicates
	var new_found_objects = _remove_duplicates(old_found_objects)
	
	return new_found_objects
	

func _query(bound: AABB) -> Array:
	"""
	:PrivateMeth
	
	Queries the QuadTree and returns the objects that exists within the bounds passed.
	"""
	_found_objects.clear()
	for object in _objects:
		var transformed_aabb = object.get_transformed_aabb()
		if bound.intersects(transformed_aabb):  # check if the object in the bounds and it's not bound
			# add the object into _found_objects
			_found_objects.push_back(object)
	if !_is_leaf:
		var child = _get_child(bound)
		if child:
			# query the child to find other objects
			_found_objects += child._query(bound)
			
		# else:
			for leaf in _children:
				# check if the leaf intersects with the bound
				if leaf._bounds.intersects(bound):
					_found_objects += leaf._query(bound)  # query the leaf for the objects
	
	return _found_objects

func _can_empty_children():
	for child in _children:
		if child == null or not child._is_leaf or not child._objects.empty():
			return false
	return true

func _unsubdivide() -> void:
	"""
	:PrivateMeth
	
	Discards all the leafs and childs with no objects.
	"""
	if _can_empty_children():
		_set_as_empty_leaf()

	if (!_objects.empty()):
		 print("has objects", _objects)
		 return  # skip if objects is not empty
	
	if (!_is_leaf):
		for child in _children:
			if !child._is_leaf or !child._objects.empty(): print("right"); return  # skip if the child is not leaf or if there're objects in the child.
	clear()  # clear the level
	if _parent:
		_parent._unsubdivide()  # unsubdivide the parent if needed.

func _get_child(body_bounds: AABB) -> QuadTree:
	"""
	:PrivateMeth
	
	Gets the child that incorporates itself in the body_bounds passed.
	"""
	if body_bounds.end.z < _bounds.position.z + _center.z:
		if body_bounds.end.x < _bounds.position.x + _center.x:
			return _children[1]  # top left
		else:
			return _children[0]  # top right
	else:
		if body_bounds.end.x < _bounds.position.x + _center.x:
			return _children[2]  # bottom left
		else:
		# elif body_bounds.position.x > _bounds.end.x:
			return _children[3]  # bottom right
	assert(false)
	return null # cannot contain boundary -- too large
	

func _create_rect_lines(points) -> void:
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

func dump(file_name = null, indent = ""):
	if file_name:
		var new_file = File.new()
		print(new_file.open("user://dumps/%s.txt" % file_name, File.WRITE))
		print("worked")
		_dump(new_file , indent)
	else:
		dump(file_name, indent)


func _dump(file_obj: File = null, indent = ""):
	if file_obj:
		file_obj.store_line("%sobjects: %s, isLeaf: %s, parent: %s" % [indent, _objects, _is_leaf, _parent])
		for child in _children:
			file_obj.store_line("%schild: %s" % [indent, child])
			if child != null:
				child._dump(file_obj, indent + "  ")
	else:
		print("%sobjects: %s" % [indent, _objects])
		for child in _children:
			print("%schild: %s" % [indent, child])
			if child != null:
				child._dump(file_obj, indent + "  ")

func draw(height: float = 1, clear_drawing: bool = true, drawer: ImmediateGeometry = null, material: Material = null) -> void:
	"""
	Initializes drawing stuff for you, you can use `_draw` method if you want to have special initialization.
	"""
	drawer = drawer if drawer else self._immediate_geo_node
	if clear_drawing:
		drawer.clear()
	if material:
		drawer.set_material_override(material)
	drawer.begin(Mesh.PRIMITIVE_LINES)
	_draw(drawer, height)
	drawer.end()
	
func _draw(drawer: ImmediateGeometry, height: float) -> void:
	"""
	:PrivateMeth
	
	Draws the visuals of QuadTree, tweak it however you want.
	"""
	
	# recursively call _draw to draw objects in different subnodes.
	for child in _children:
		if not _is_leaf:
			child._draw(drawer, height)
	var points = []
	# initialize the points
	_create_rect_lines(points)
	
	# draw them into the node.
	for point in points:
		drawer.add_vertex(Vector3(point.x, height, point.y)) # change it to x and y axis if needed.
	
	# draw the bodies
	for body in _objects:
		# convert aabb to rect for easier usage
		var rect = _convert_aabb_to_rect(body.get_transformed_aabb())
		
		# get all 4 points
		var Bpoint = Vector3(rect.end.x, height, rect.position.y)
		var Dpoint = Vector3(rect.position.x, height,  rect.end.y)
		var Apoint = Vector3(rect.position.x, height, rect.position.y)
		var Cpoint = Vector3(rect.end.x, height, rect.end.y)
		
		# add them here
		drawer.add_vertex(Apoint)
		drawer.add_vertex(Bpoint)
		drawer.add_vertex(Bpoint)
		drawer.add_vertex(Cpoint)
		drawer.add_vertex(Cpoint)
		drawer.add_vertex(Dpoint)
		drawer.add_vertex(Dpoint)
		drawer.add_vertex(Apoint)
	
static func _convert_aabb_to_rect(transformed_aabb: AABB) -> Rect2:
	"""
	:StaticMeth
	
	Converts a AABB to Rect2
	"""
	return Rect2(Vector2(transformed_aabb.position.x, transformed_aabb.position.z), Vector2(transformed_aabb.size.x, transformed_aabb.size.z))  # assumed as XZ plane

static func _remove_duplicates(a_list: Array) -> Array:
	"""
	:StaticMeth
	
	Removes all duplicates in an Array.
	"""
	var seen = {}

	for i in range(a_list.size()):
		var v = a_list[i]
		seen[v] = true

	return seen.keys()
