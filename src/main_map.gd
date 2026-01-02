extends Node2D

signal unit_added(is_player: bool, unit_id: String, unit_priority: int)
signal unit_removed(is_player: bool, unit_id: String)

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
		$"UI Layer".visible = true
		$"UI Layer/UI/EndGame".visible = map_state == MapState.EndGame
		$"UI Layer/UI/Town".visible = map_state == MapState.Town
		$"UI Layer/UI/Battle".visible = map_state == MapState.Battle
		$"UI Layer/UI/Mine".visible = map_state == MapState.Mine

@export var _end_game_label_path: NodePath
@onready var end_game_label: Label = get_node(_end_game_label_path)
@export var _units_capacity_label_path: NodePath
@onready var units_capacity_label: Label = get_node(_units_capacity_label_path)
@export var _select_texture_path: NodePath
@onready var select_texture: TextureRect = get_node(_select_texture_path)
@export var _camera_path: NodePath
@onready var camera: Camera2D = get_node(_camera_path)
@export var _price_nodes: Dictionary[String, NodePath]
@export var _circular_progress_bar_nodes: Dictionary[String, NodePath]
@export var _money_nodes: Array[NodePath]


func _ready() -> void:
	WS.new_data_received.connect(_on_WS_new_data_recieved)
	WS.socket_closed.connect(_on_WS_socket_closed)
	
	unit_added.connect($PlayerTower._on_unit_added)
	unit_removed.connect($PlayerTower._on_unit_removed)
	unit_added.connect($EnemyTower._on_unit_added)
	unit_removed.connect($EnemyTower._on_unit_removed)
	
	map_state = map_state
	$"UI Layer/UI/Town".position = Vector2.ZERO
	$"UI Layer/UI/Mine".position = Vector2.ZERO
	spawn_request("miner")
	for path in _circular_progress_bar_nodes.values():
		var circular_progress_bar: CircularProgressBar = get_node(path)
		circular_progress_bar.visible = false

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
				get_node(_price_nodes.get(el[0])).text = str(int(el[1]))
			$PlayerTower.init_matrix(data.units_capacity)
			$EnemyTower.init_matrix(data.units_capacity)
			units_capacity_label.text = "0/{0}".format([int(data.units_capacity)])
		"end_game":
			UserInfo.set_room_id("")
			get_tree().paused = true
			end_game_label.text = "Победитель " + data.winner
			map_state = MapState.EndGame
		"spawn":
			spawn_unit(true, JSON.parse_string(data.unit_info))
			update_money_text(data.money)
			if data.has("new_miner_price"):
				get_node(_price_nodes.miner).text = str(int(data.new_miner_price))
		"spawn_enemy":
			spawn_unit(false, JSON.parse_string(data.unit_info))
		"spawn_ore":
			spawn_ore(data.ore)
		"sell_ore":
			update_money_text(data.money)


func spawn_request(unit_name: String) -> void:
	if !is_instance_valid(WS.socket):
		return
	var info = {
		type = "spawn",
		unit_name = unit_name,
	}
	var error = WS.socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

func spawn_unit(is_player: bool, data: Dictionary) -> void:
	var unit: Unit = Global.units[data.name].instantiate()
	var pos = Vector2(0, data.y)
	unit.is_player = is_player
	unit.update_info(data)
	if is_player:
		unit.tower_node = $PlayerTower
		if data.unit_type == "miner":
			pos = $"PlayerTower".global_position
		else:
			pos.x = $"PlayerTower".global_position.x
	else:
		unit.tower_node = $"EnemyTower"
		pos.x = $"EnemyTower".global_position.x
	unit.global_position = pos
	unit.destroyed.connect(_on_unit_destroyed)
	$"Units".add_child(unit)
	if data.priority != null:
		unit_added.emit(is_player, data.id, data.priority)
		units_capacity_label.text = "{0}/{1}".format([
			$PlayerTower.get_unit_count(),
			$PlayerTower.defence_matrix.size()
		])
	if is_player:
		var circular_progress_bar: CircularProgressBar = get_node(_circular_progress_bar_nodes[data.name])
		circular_progress_bar.visible = true
		circular_progress_bar.start(data.cooldown)
		await circular_progress_bar.animation_finished
		circular_progress_bar.visible = false

func spawn_ore(data: Dictionary) -> void:
	print("spawn_ore")
	var ore = preload("res://scene/ore.tscn").instantiate()
	ore.update_info(data)
	ore.position.x = data.x
	ore.position.y = data.y
	$MineLocation/Ores.add_child(ore)

func update_money_text(new_money: int) -> void:
	for path in _money_nodes:
		get_node(path).text = str(new_money)


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
	spawn_request("soldier")

func _on_archer_button_pressed() -> void:
	spawn_request("samurai")

func _on_minotaur_button_pressed() -> void:
	spawn_request("minotaur")

func _on_miner_button_pressed() -> void:
	spawn_request("miner")

func _on_witch_button_pressed() -> void:
	spawn_request("witch")

func _on_exit_btn_pressed() -> void:
	if WS.socket != null:
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

func _on_unit_destroyed(is_player: bool, unit_id: String) -> void:
	unit_removed.emit(is_player, unit_id)
	units_capacity_label.text = "{0}/{1}".format([
		$PlayerTower.get_unit_count(),
		$PlayerTower.defence_matrix.size()
	])

func _on_attack_button_pressed() -> void:
	var button = $"UI Layer/UI/Battle/VBoxContainer/AttackButton"
	select_texture.reparent(button, false)
	$PlayerTower.tower_state = Tower.TowerState.Attack
	WS.socket.send_text(JSON.stringify({type = "go_attack"}))

func _on_defence_button_pressed() -> void:
	var button = $"UI Layer/UI/Battle/VBoxContainer/DefenceButton"
	select_texture.reparent(button, false)
	$PlayerTower.tower_state = Tower.TowerState.Defence
	WS.socket.send_text(JSON.stringify({type = "go_defence"}))
