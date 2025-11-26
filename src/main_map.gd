extends Node2D


const UNIT_SCENE = preload("res://scene/soldier.tscn")
var camera_speed = 50

@export var _end_game_label_path: NodePath
@onready var end_game_label: Label = get_node(_end_game_label_path)


func _ready() -> void:
	Api.connect("new_data_recived", _on_Api_new_data_recieved)
	Api.connect("socket_closed", _on_Api_socket_closed)

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
	match data.type:
		"start_game":
			prints("Опонент подключился, игра началась!");
		"end_game":
			get_tree().paused = true
			end_game_label.text = "Победитель " + data.winner
			$"UI Layer/UI/EndGame".visible = true
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
	}
	var error = Api.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func _on_archer_button_pressed() -> void:
	var info = {
		type = "spawn",
		unit_name = "archer",
	}
	var error = Api.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func _on_exit_btn_pressed() -> void:
	Api.socket.close()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_Api_socket_closed() -> void:
	get_tree().paused = true
	end_game_label.text = "Соединение с сервером разорвано. %s, Ты проиграл!" % [UserInfo.get_user_info().username]
	$"UI Layer/UI/EndGame".visible = true
