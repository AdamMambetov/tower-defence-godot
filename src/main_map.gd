extends Node2D


enum MapState {
	Battle,
	Town,
	Mine,
	EndGame,
}

const UNIT_SCENE = preload("res://scene/soldier.tscn")
const CONNECTION_CLOSED_TEXT = "Соединение с сервером разорвано. %s, Ты проиграл!"

var camera_speed: float = 50.0
var move_by_mouse: bool = true
var map_state: MapState = MapState.Battle:
	set(value):
		map_state = value
		$"UI Layer/UI/EndGame".visible = map_state == MapState.EndGame
		$"UI Layer/UI/Town".visible = map_state == MapState.Town
		$"UI Layer/UI/Battle".visible = map_state == MapState.Battle
		$"UI Layer/UI/Mine".visible = map_state == MapState.Mine

@export var _end_game_label_path: NodePath
@onready var end_game_label: Label = get_node(_end_game_label_path)
@export var _money_value_path: NodePath
@onready var money_value: Label = get_node(_money_value_path)
@export var _camera_path: NodePath
@onready var camera: Camera2D = get_node(_camera_path)
@export var _price_nodes: Dictionary[String, NodePath]


func _ready() -> void:
	WS.new_data_received.connect(_on_WS_new_data_recieved)
	WS.socket_closed.connect(_on_WS_socket_closed)
	
	map_state = map_state
	$"UI Layer/UI/Town".position = Vector2.ZERO
	$"UI Layer/UI/Mine".position = Vector2.ZERO

func _process(_delta: float) -> void:
	if move_by_mouse:
		_update_camera()


func _update_camera() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size
	var camera_scale = remap(mouse_pos.x, 0, viewport_size.x, -1, 1)
	
	if abs(camera_scale) > 0.6:
		camera_scale = remap(camera_scale, 0.6, 1, 0, 1) if camera_scale > 0 \
				else remap(camera_scale, -1, -0.6, -1, 0)
		camera.position.x = clampf(
			camera.position.x + camera_speed * camera_scale,
			camera.limit_left,
			camera.limit_right,
		)

func _new_data_handler(data: Dictionary) -> void:
	match data.type:
		"start_game":
			prints("Опонент подключился, игра началась!");
			var prices = JSON.parse_string(data.hero_prices)
			for el in prices:
				get_node(_price_nodes.get(el[0])).text = str(el[1])
		"end_game":
			UserInfo.set_room_id("")
			get_tree().paused = true
			end_game_label.text = "Победитель " + data.winner
			map_state = MapState.EndGame
		"spawn":
			spawn_unit(true, JSON.parse_string(data.unit_info))
			money_value.text = str(int(data.money))
		"spawn_enemy":
			spawn_unit(false, JSON.parse_string(data.unit_info))


func spawn_unit(is_player: bool, data: Dictionary) -> void:
	var unit = Global.units[data.name].instantiate()
	unit.is_player = is_player
	unit.update_info(data)
	if is_player:
		if data.unit_type == "miner":
			unit.global_position = $MinerSpawn.global_position
		else:
			unit.global_position = $"PlayerTower".get_spawn_position()
	else:
		unit.global_position = $"EnemyTower".get_spawn_position()
	$"Units".add_child(unit)


func _on_WS_new_data_recieved(result: Dictionary) -> void:
	if result.has("success"):
		if !result.success:
			return
	_new_data_handler(result)

func _on_WS_socket_closed() -> void:
	if get_tree() != null:
		get_tree().paused = true
	end_game_label.text = CONNECTION_CLOSED_TEXT % [
		UserInfo.get_user_info().username,
	]
	map_state = MapState.EndGame

func _on_soldier_button_pressed() -> void:
	var info = {
		type = "spawn",
		unit_name = "soldier",
	}
	var error = WS.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func _on_archer_button_pressed() -> void:
	var info = {
		type = "spawn",
		unit_name = "samurai",
	}
	var error = WS.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func _on_minotaur_button_pressed() -> void:
	var info = {
		type = "spawn",
		unit_name = "minotaur",
	}
	var error = WS.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func _on_miner_button_pressed() -> void:
	var info = {
		type = "spawn",
		unit_name = "miner",
	}
	var error = WS.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func _on_witch_button_pressed() -> void:
	var info = {
		type = "spawn",
		unit_name = "witch",
	}
	var error = WS.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func _on_exit_btn_pressed() -> void:
	WS.socket.close()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_go_battle_button_pressed() -> void:
	map_state = MapState.Battle
	camera.position.x = 0
	await get_tree().create_timer(0.2).timeout
	camera.limit_left = 0
	move_by_mouse = true

func _on_go_town_button_pressed() -> void:
	move_by_mouse = false
	camera.make_current()
	map_state = MapState.Town
	camera.limit_left = -1152
	camera.position.x = -1152

func _on_go_mine_button_pressed() -> void:
	move_by_mouse = false
	map_state = MapState.Mine
	$MineLocation/Camera.make_current()
	pass
