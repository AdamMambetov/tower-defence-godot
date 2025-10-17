extends Node2D

var camera_speed = 20


func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size
	var camera_scale = remap(mouse_pos.x, 0, viewport_size.x, -1, 1)
	if abs(camera_scale) > 0.6:
		# TODO: move camera on begin or end screen
		#camera_scale = remap(camera_scale, -1, 1, 0, 1)
		#$Camera2D.position.x = clampf(
			#$Camera2D.position.x + camera_speed * camera_scale,
		#)
		pass
