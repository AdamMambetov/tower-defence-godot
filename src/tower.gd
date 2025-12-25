@tool
extends Node2D


@export var is_player: bool:
	set(value):
		is_player = value
		update_scale()

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
	if is_instance_valid(WS):
		WS.new_data_received.connect(_on_WS_new_data_received)
	tower_area.set_collision_layer_value(2, is_player)
	tower_area.set_collision_layer_value(3, !is_player)
	tower_area.set_collision_mask_value(2, !is_player)
	tower_area.set_collision_mask_value(3, is_player)
	update_scale()


func update_scale() -> void:
	if !is_instance_valid($TowerArea):
		return
	if is_player:
		$TowerArea.scale.x = 1
	else:
		$TowerArea.scale.x = -1


func _on_WS_new_data_received(result: Dictionary) -> void:
	if result.type != "attack":
		return
	
	if result.has("me_tower") and is_player:
		health = result.me_tower
		prints("me_tower", result.me_tower)
	elif result.has("enemy_tower") and !is_player:
		health = result.enemy_tower
		prints("enemy_tower", result.enemy_tower)
