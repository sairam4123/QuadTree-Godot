extends MeshInstance

var new_mesh: MeshInstance
export(NodePath) var root_qt_node_path
onready var root_qt_node = get_node(root_qt_node_path)
var random_seed_to_use = null

var is_ready = false
func _ready() -> void:

	if random_seed_to_use == null:
		randomize()
		random_seed_to_use = int(rand_range(-100000, 100000))
	print("Using seed: %s" % random_seed_to_use)
	seed(random_seed_to_use)

	# create quadtree
	# create 100 objects to test out quad tree
	for i in range(10):
		# create new mesh instance
		var new_mesh = MeshInstance.new()
		# create a new cube mesh
		var cube_mesh = CubeMesh.new()
		# create a new mat
		var cube_mat = SpatialMaterial.new()
		# set it's size random from 2, 4 
		cube_mesh.size = Vector3(rand_range(2, 4), 0, rand_range(2, 4))
		new_mesh.mesh = cube_mesh
		cube_mat.albedo_color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), 1)
		new_mesh.material_override = cube_mat
		# set the position random from -25 to 25 -- size of the terrain
		new_mesh.set_translation(Vector3(rand_range(-100, 100), 0.1, rand_range(-100, 100)))
		add_child(new_mesh)
		# add it into the quad tree
		root_qt_node.add_body(new_mesh)
		if i % 100 == 0:
			yield(get_tree(), "idle_frame")
	# test query -- create a new sphere mesh and set it's radius to 5
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = rand_range(5, 8)
	sphere_mesh.height = 0.1
	# create a new meshinstance and set it's translation to `Vector3(4, 0, 4)`
	new_mesh = MeshInstance.new()
	new_mesh.set_translation(Vector3(rand_range(2, 6), 0, rand_range(2, 6)))
	# hide it, because we don't want it to be shown.
#	new_mesh.hide()
	# set the mesh and add it into the scene
	new_mesh.mesh = sphere_mesh
	add_child(new_mesh)
	# query the QuadTree with the sphere mesh's Tranformed AABB
	var returned_objects = root_qt_node.query(new_mesh.get_transformed_aabb())
	
	# print the returned objects
#	print(returned_objects)
#	print(returned_objects.size())

	# visualize the quad tree
	root_qt_node.draw(0.2, true, false)
	is_ready = true
	

func _process(delta: float) -> void:
		if !is_ready:
			return
		var mouse_pointer = get_viewport().get_mouse_position()
		var camera = get_viewport().get_camera()
		var from = camera.project_ray_origin(mouse_pointer)
		var to = from + camera.project_ray_normal(mouse_pointer) * 1000
		var ray = get_world().direct_space_state.intersect_ray(from, to, [self, camera])
		if !ray.empty():
			new_mesh.set_translation(ray['position'])
			if Input.is_action_pressed("left_button"):
				var transformed_aabb = new_mesh.get_transformed_aabb()
				transformed_aabb.size.y += 10000
				transformed_aabb.position.y -= 50
				# print(transformed_aabb)
				var returned_objects = root_qt_node.query(transformed_aabb)
#				print(returned_objects)
				for object in returned_objects:
#					print(object.has_meta("_qt"))
					root_qt_node.remove_body(object)
					object.call_deferred("queue_free")
				root_qt_node.draw(0.2, true, false)

func _input(event):
	if event.is_action_pressed("ui_select"):		# space bar
		print("Dump:")
		root_qt_node.dump("dump")
