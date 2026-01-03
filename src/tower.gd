@tool
class_name Tower extends Node2D


signal tower_state_changed(old: String, new: String)


class TowerState:
	const Attack = "attack"
	const Defence = "defence"

class DefenceItem:
	var id: String
	var priority: int


@export var is_player: bool:
	set(value):
		is_player = value
		update_scale()

@export var spawn_range_y: Vector2:
	set(value):
		spawn_range_y = value
		if is_instance_valid($SpawnArea/SpawnCollision):
			$SpawnArea/SpawnCollision.shape.size = value
@export var defence_position: Vector2:
	set(value):
		defence_position = value
		if is_instance_valid($DefenceShapeCast):
			$DefenceShapeCast.position = Vector2(0, defence_position.y)
			$DefenceShapeCast.target_position = Vector2(defence_position.x, 0)
var defence_range_x: Array = [-55.0, 0.0, 55.0]
var defence_range_y: Array = [-38.4, 0.0, 38.4]
var defence_matrix: Array[DefenceItem] = []

var id: String = "tower"

var health: float = 1000:
	set(value):
		health = value
		if health <= 0.0:
			health = 0.0
		$PlayerHealthBar.value = health
		$PlayerHealthBar/HealthValue.text = str(int(health))

var tower_state: String = TowerState.Defence:
	set(value):
		if tower_state == value:
			return
		var old = tower_state
		tower_state = value
		tower_state_changed.emit(old, tower_state)
		_send_tower_state()

@export var _tower_area_path: NodePath
@onready var tower_area: Area2D = get_node(_tower_area_path)

@export var _tower_collition_path: NodePath
@onready var tower_collition: CollisionShape2D = get_node(_tower_collition_path)

@export var _defence_shape_cast_path: NodePath
@onready var defence_shape_cast: ShapeCast2D = get_node(_defence_shape_cast_path)


func _ready() -> void:
	if is_instance_valid(WS):
		WS.new_data_received.connect(_on_WS_new_data_received)
	tower_area.set_collision_layer_value(2, is_player)
	tower_area.set_collision_layer_value(3, !is_player)
	tower_area.set_collision_mask_value(2, !is_player)
	tower_area.set_collision_mask_value(3, is_player)
	defence_shape_cast.set_collision_mask_value(2, !is_player)
	defence_shape_cast.set_collision_mask_value(3, is_player)
	update_scale()


func init_matrix(size: int) -> void:
	defence_matrix.clear()
	for _i in range(size):
		defence_matrix.push_back(DefenceItem.new())

func update_scale() -> void:
	if !is_instance_valid($TowerArea):
		return
	if is_player:
		$TowerArea.scale.x = 1
	else:
		$TowerArea.scale.x = -1

func get_defence_position(unit_id: String) -> Vector2:
	var idx = defence_matrix.find_custom(func(a): return a.id == unit_id)
	if idx == -1:
		return Vector2.ZERO
	var column = idx / 3
	var row = idx % 3
	var result = defence_shape_cast.global_position
	result.x += defence_position.x
	result.y += defence_range_y[row]
	result.x += defence_range_x[0 if is_player else 2] * column
	return result

func get_unit_count() -> int:
	var res = 0
	for el in defence_matrix:
		if !el.id.is_empty():
			res += 1
	return res

func has_enemies() -> bool:
	return defence_shape_cast.is_colliding()


func _send_tower_state() -> void:
	if !is_player:
		return
	var type = "go_attack"
	match tower_state:
		TowerState.Defence:
			type = "go_defence"
	WS.socket.send_text(JSON.stringify({ type = type }))


func _on_WS_new_data_received(result: Dictionary) -> void:
	match result.type:
		"attack":
			if result.has("me_tower") and is_player:
				health = result.me_tower
				prints("me_tower", result.me_tower)
			elif result.has("enemy_tower") and !is_player:
				health = result.enemy_tower
				prints("enemy_tower", result.enemy_tower)
		"go_attack":
			if !is_player:
				tower_state = TowerState.Attack
		"go_defence":
			if !is_player:
				tower_state = TowerState.Defence

func _on_unit_added(unit_is_player: bool, unit_id: String, unit_priority: int) -> void:
	if unit_is_player != is_player:
		return
	for i in range(0, defence_matrix.size()):
		var el = defence_matrix[i]
		if el.id.is_empty():
			defence_matrix[i].id = unit_id
			defence_matrix[i].priority = unit_priority
			break
	defence_matrix.sort_custom(func(a, b): return a.priority > b.priority)

func _on_unit_removed(unit_is_player: bool, unit_id: String) -> void:
	if unit_is_player != is_player:
		return
	var idx = defence_matrix.find_custom(func(a): return a.id == unit_id)
	if idx == -1:
		return
	defence_matrix[idx].id = ""
