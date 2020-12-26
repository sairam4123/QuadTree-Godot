# QuadTree-Godot
A QuadTree using AABB and Vector3s.

Just a rewrite of https://github.com/m-byte918/QuadTree-Cpp in GDScript.

Any feedback welcome!

Special Thanks to:
1. xananax, for helping me to figure out how to do QuadTrees in Godot
2. gvdb and AgreesiveGaming for their basic QuadTree implementation in Godot.
3. Calinou, for helping to fix some bugs.
4. recylops, for providing me the resources to read.
5. Pikol93, for guiding me and providing support and answering my questions.
6. Zylann, for helping me to find the equivalent GDScript from C++.  

And big thanks to jaynabonne, for helping me to fix the regression that happend.

# How to use this?:
## Initialization of QuadTree:
```gdscript
var quad_tree = QuadTree.new(bounds, capacity, max_level)
```
## Adding objects into QuadTree, use MeshInstance:
```gdscript
# get mesh
quad_tree.add_body(mesh)  
# You can also save the object that this being returned, then you can remove it directly without using Query.
mesh = quad_tree.add_body(mesh)
```
## Removing objects from QuadTree, use Query to get objects instead of making your own:
```gdscript
# query quadtree and get objects
for object in queried_objects: # assumed the name is queried_objects
  quad_tree.remove(object) # makesure to use query so it returns the quad tree connected to it.
# if you don't want to query, save the object that is being returned when it is being added to the quad tree and just remove it
quad_Tree.remove_body(mesh)
```
## Querying objects from QuadTree
```gdscript
  var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = rand_range(5, 8)
	sphere_mesh.height = 0.1
	# create a new meshinstance and set it's translation to `Vector3(4, 0, 4)`
	new_mesh = MeshInstance.new()
	new_mesh.set_translation(Vector3(rand_range(2, 6), 0, rand_range(2, 6)))
	# set the mesh and add it into the scene
	new_mesh.mesh = sphere_mesh
	add_child(new_mesh)
  
  # after the init work we'll now do a query and fetch objects
  var returned_objects = quad_tree.query(new_mesh.get_transformed_aabb()) # Use Transformed AABB so the code doesn't breaks.
  
  # let's print it
  print(returned_objects)
```
## Updating objects in QuadTree, moving objects
```gdscript
# use the add method or query method to fetch object
# assuming `moving_object` is you object
moving_object.translate(Vector3(5, 0, 0))  # move the object 5 units in x axis
quad_tree.update_body(moving_objects)  # update the object

# now again do query and check if it is updated
... # do it yourself
# done
```
## Clearing the QuadTree
```gdscript
quad_tree.clear() # done.
```
