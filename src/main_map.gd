extends Node2D


const UNIT_SCENE = preload("res://scene/unit.tscn")
var camera_speed = 50


func _ready() -> void:
	Api.connect("new_data_recived", _on_Api_new_data_recieved)

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

func _new_data_handler(data: Dictionary) -> void:
	match data.get("type"):
		"start_game": prints("Опонент подключился, игра началсь!");
		"end_game": prints("Игра закончена ")
		"spawn":
			var unit = UNIT_SCENE.instantiate()
			unit.is_player = false
			unit.global_position = $"Game Layer/EnemyTower".get_spawn_position()
			unit.update_info(data.enemy)
			$"Game Layer".add_child(unit)


func _on_Api_new_data_recieved(success: bool, result: Dictionary) -> void:
	if success:
		_new_data_handler(result)

func _on_minion_button_pressed() -> void:
	var info = {
		type = "spawn",
		enemy = {
			speed = randi_range(10, 50),
			damage = randi_range(5, 20),
			health = randi_range(30, 100),
		}
	}
	Api.socket.send_text(JSON.stringify(info))
	
	var unit = UNIT_SCENE.instantiate()
	unit.global_position = $"Game Layer/PlayerTower".get_spawn_position()
	unit.is_player = true
	unit.update_info(info.enemy)
	$"Game Layer".add_child(unit)

func _on_minion_button_2_pressed() -> void:
	pass # Replace with function body.
