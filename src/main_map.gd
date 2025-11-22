extends Node2D


const UNIT_SCENE = preload("res://scene/soldier.tscn")
var camera_speed = 50


func _ready() -> void:
	Api.connect("new_data_recived", _on_Api_new_data_recieved)
	
	#for i in 3:
		#var info = {
			#type = "spawn",
			#enemy = {
				#speed = randi_range(10, 50),
				#damage = randi_range(5, 20),
				#health = randi_range(30, 100),
				#attack_speed = randf_range(0.5, 3.0),
			#}
		#}
		#var unit = UNIT_SCENE.instantiate()
		#unit.global_position = $"Game Layer/EnemyTower".get_spawn_position()
		#unit.is_player = false
		#unit.update_info(info.enemy)
		#$"Game Layer/Units".add_child(unit)

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
		"start_game": prints("Опонент подключился, игра началась!");
		"end_game": prints("Игра закончена!")
		"spawn":
			spawn_unit(true, JSON.parse_string(data.unit_info))
			$"UI Layer/UI/MoneyValue".text = str(int(data.money))
		"spawn_enemy":
			spawn_unit(false, JSON.parse_string(data.unit_info))


func spawn_unit(is_player: bool, data: Dictionary) -> void:
	var unit = Global.units[data.name].instantiate()
	unit.is_player = is_player
	unit.is_archer = data.name == "archer"
	unit.update_info(data)
	if is_player:
		unit.global_position = $"Game Layer/PlayerTower".get_spawn_position()
	else:
		unit.global_position = $"Game Layer/EnemyTower".get_spawn_position()
	$"Game Layer/Units".add_child(unit)


func _on_Api_new_data_recieved(result: Dictionary) -> void:
	if result.has("success"):
		if !result.success:
			return
	_new_data_handler(result)

func _on_soldier_button_pressed() -> void:
	var info = {
		type = "spawn",
		unit_name = "knight",
		#enemy = {
			#speed = randi_range(10, 50),
			#damage = randi_range(5, 20),
			#health = randi_range(30, 100),
			#attack_speed = randf_range(0.5, 3.0),
		#}
	}
	var error = Api.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func _on_archer_button_pressed() -> void:
	var info = {
		type = "spawn",
		unit_name = "archer",
		#enemy = {
			#speed = randi_range(10, 50),
			#damage = randi_range(5, 20),
			#health = randi_range(30, 100),
			#attack_speed = randf_range(0.5, 3.0),
		#}
	}
	var error = Api.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)
