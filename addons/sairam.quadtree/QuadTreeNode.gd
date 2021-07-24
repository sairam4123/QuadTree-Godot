extends Spatial

const QuadTree = preload("res://addons/sairam.quadtree/QuadTree.gd")

export var bounds: AABB
export var capacity: int
export var max_levels: int

export(NodePath) var immediate_geo_node_path
onready var immediate_geo_node = get_node(immediate_geo_node_path)

var _quad_tree: QuadTree

func _ready():
	_quad_tree = QuadTree.new(bounds, capacity, max_levels)
	_quad_tree.set_drawing_node(immediate_geo_node)

func add_body(body: Spatial, bounds: AABB = AABB()):
	return _quad_tree.add_body(body, bounds)

func remove_body(body: Spatial):
	return _quad_tree.remove_body(body)

func update_body(body: Spatial, bounds: AABB = AABB()):
	return _quad_tree.update_body(body, bounds)

func clear():
	return _quad_tree.clear()

func query(bounds: AABB):
	return _quad_tree.query(bounds)

func draw(height: float = 1, clear_drawing: bool = true, draw_outlines: bool = true, draw_tree_bounds: bool = true):
	return _quad_tree.draw(height, clear_drawing, draw_outlines, draw_tree_bounds)
