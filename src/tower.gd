@tool
extends Node2D


@export var is_player: bool:
	set(value):
		is_player = value
		if !is_instance_valid($TowerArea) or !is_instance_valid($Area2D):
			return
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
		$PlayerHealthBar.value = health
		$PlayerHealthBar/HealthValue.text = str(int(health))

@export var _tower_area_path: NodePath
@onready var tower_area: Area2D = get_node(_tower_area_path)


func _ready() -> void:
	WS.new_data_received.connect(_on_WS_new_data_received)
	is_player = is_player
	tower_area.set_collision_layer_value(2, is_player)
	tower_area.set_collision_layer_value(3, !is_player)
	tower_area.set_collision_mask_value(2, !is_player)
	tower_area.set_collision_mask_value(3, is_player)

func _physics_process(_delta: float) -> void:
	$"Area2D/SpawnAreaPreview".shape.size = spawn_range_y


func get_spawn_position() -> Vector2:
	var result = $Area2D/SpawnAreaPreview.global_position
	result.y += randf_range(-spawn_range_y.y, spawn_range_y.y)
	return result


func _on_WS_new_data_received(result: Dictionary) -> void:
	if result.type != "attack":
		return
	
	if result.has("me_tower") and tower_area.get_collision_layer_value(2):
		health = result.me_tower
	elif result.has("enemy_tower") and tower_area.get_collision_layer_value(3):
		health = result.enemy_tower
