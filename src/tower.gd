extends Area2D


@export var spawn_range_y: Vector2
var id: String = "tower"

var health: float = 100:
	set(value):
		health = value
		if health <= 0.0:
			health = 0.0
		$PlayerHealthBar.value = health


func _ready() -> void:
	Api.connect("new_data_recived", _on_Api_new_data_recieved)
	get_collision_layer_value(2)


func get_spawn_position() -> Vector2:
	var result = $"UnitSpawnPlayer".global_position \
		if get_collision_layer_value(2) \
		else $"UnitSpawnEnemy".global_position
	result.y += randf_range(spawn_range_y.x, spawn_range_y.y)
	return result


func _on_Api_new_data_recieved(result: Dictionary) -> void:
	if result.type != "attack":
		return
	
	if result.has("me_tower") and get_collision_layer_value(2):
		health = result.me_tower
	elif result.has("enemy_tower") and get_collision_layer_value(3):
		health = result.enemy_tower
