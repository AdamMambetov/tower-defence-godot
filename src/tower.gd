extends Node2D


@export var is_player: bool
@export var spawn_range_y: Vector2

var id: String = "tower"

var health: float = 100:
	set(value):
		health = value
		if health <= 0.0:
			health = 0.0
		$TowerArea/PlayerHealthBar.value = health

@export var _tower_area_path: NodePath
@onready var tower_area: Area2D = get_node(_tower_area_path)


func _ready() -> void:
	WS.new_data_received.connect(_on_WS_new_data_received)
	tower_area.set_collision_layer_value(2, is_player)
	tower_area.set_collision_layer_value(3, !is_player)
	tower_area.set_collision_mask_value(2, !is_player)
	tower_area.set_collision_mask_value(3, is_player)


func get_spawn_position() -> Vector2:
	var result = $TowerArea/UnitSpawnPlayer.global_position \
		if tower_area.get_collision_layer_value(2) \
		else $TowerArea/UnitSpawnEnemy.global_position
	result.y += randf_range(spawn_range_y.x, spawn_range_y.y)
	return result


func _on_WS_new_data_received(result: Dictionary) -> void:
	if result.type != "attack":
		return
	
	if result.has("me_tower") and tower_area.get_collision_layer_value(2):
		health = result.me_tower
	elif result.has("enemy_tower") and tower_area.get_collision_layer_value(3):
		health = result.enemy_tower
