@tool
extends Node2D


@export var is_player: bool = false:
	set(value):
		is_player = value
		if is_player:
			$TowerArea.scale.x = 1
			$Area2D.scale.x = 1
		else:
			$TowerArea.scale.x = -1
			$Area2D.scale.x = -1

@export var spawn_range_y: Vector2

var id: String = "tower"

var health: float = 1000:
	set(value):
		health = value
		if health <= 0.0:
			health = 0.0
		$TowerArea/PlayerHealthBar.value = health
		$TowerArea/PlayerHealthBar/HealthValue.text = str(int(health))

@export var _tower_area_path: NodePath
@onready var tower_area: Area2D = get_node(_tower_area_path)


func _ready() -> void:
	WS.new_data_received.connect(_on_WS_new_data_received)
	tower_area.set_collision_layer_value(2, is_player)
	tower_area.set_collision_layer_value(3, !is_player)
	tower_area.set_collision_mask_value(2, !is_player)
	tower_area.set_collision_mask_value(3, is_player)
	scale.x *= -1 if !is_player else 1

func _physics_process(_delta: float) -> void:
	$"Area2D/SpawnAreaPreview".shape.size = spawn_range_y


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
