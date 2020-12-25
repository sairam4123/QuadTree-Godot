tool
extends EditorPlugin



func _enter_tree() -> void:
	add_autoload_singleton("MetaStaticFuncs", "res://addons/sairam.quadtree/Meta_Static_Funcs.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("MetaStaticFuncs")
