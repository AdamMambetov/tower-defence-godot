extends Node2D


var camera_speed = 50


func _process(_delta: float) -> void:
	_update_camera()
 

func _update_camera() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size
	var camera_scale = remap(mouse_pos.x, 0, viewport_size.x, -1, 1)
	
	if abs(camera_scale) > 0.6:
		camera_scale = remap(camera_scale, 0.6, 1, 0, 1) if camera_scale > 0 \
				else remap(camera_scale, -1, -0.6, -1, 0)
		$Camera2D.position.x = clampf(
			$Camera2D.position.x + camera_speed * camera_scale,
			$Camera2D.limit_left,
			$Camera2D.limit_right,
		)
		print($Camera2D.position.x)


func _on_enemy_tower_input_event(
		_viewport: Node,
		event: InputEvent,
		_shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if !event.pressed:
			print("jfkdjfkdjf")
