extends Node2D


var current_bg_idx: int = 0
var next_bg_idx: int = 1

@export var _bg_paths: Array[NodePath]
var bg_nodes: Array[Node2D]


func _ready() -> void:
	for path in _bg_paths:
		var node = get_node(path)
		if node is not Node2D:
			printerr("BG is not a Node2D!!!!!!!")
			return
		bg_nodes.push_back(node)

func _process(delta: float) -> void:
	if bg_nodes.is_empty():
		return
	for node in bg_nodes:
		var parallaxes = node.get_children()
		for p: Parallax2D in parallaxes:
			var speed = 40.0 * delta * p.scroll_scale.x
			p.scroll_offset.x -= speed


func next_bg() -> void:
	current_bg_idx = (current_bg_idx + 1) % bg_nodes.size()
	next_bg_idx = (current_bg_idx + 1) % bg_nodes.size()

func go_next_bg() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(bg_nodes[current_bg_idx], "modulate:a", 0, 3)
	tween.parallel()
	tween.tween_property(bg_nodes[next_bg_idx], "modulate:a", 1, 3)
	tween.tween_callback(next_bg)
	tween.play()


func _on_timer_timeout() -> void:
	go_next_bg()
