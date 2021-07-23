tool
extends EditorPlugin

var quad_tree = load("res://addons/sairam.quadtree/QuadTreeNode.gd")
var quad_tree_icon = load("res://addons/sairam.quadtree/Tree.svg")

func _enter_tree() -> void:
	add_autoload_singleton("MetaStaticFuncs", "res://addons/sairam.quadtree/Meta_Static_Funcs.gd")
	add_custom_type("QuadTreeNode", "Spatial", quad_tree, quad_tree_icon)


func _exit_tree() -> void:
	remove_autoload_singleton("MetaStaticFuncs")
	remove_custom_type("QuadTreeNode")
