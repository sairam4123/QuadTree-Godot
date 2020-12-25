extends Node

func _ready() -> void:
	randomize()
	# create quadtree
	var root_qt_node = QuadTree.create_quadtree(AABB(Vector3(-25, 0, -25), Vector3(50, 0, 50)), 5, 5)
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
	sphere_mesh.radius = rand_range(5, 8)
	sphere_mesh.height = 0.1
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
	print(returned_objects.size())

	# visualize the quad tree
	var spatial_mat = SpatialMaterial.new()
	spatial_mat.albedo_color = Color(0, 0, 0, 1)
	root_qt_node.draw(get_node("/root/Spatial/ImmediateGeometry"), spatial_mat, 0.2)
	

func _physics_process(delta: float) -> void:
	pass
