extends Area2D


@export var spawn_range_y: Vector2


var health: float = 100:
	set(value):
		health = value
		if health <= 0.0:
			health = 0.0
		$PlayerHealthBar.value = health


func _ready() -> void:
	get_collision_layer_value(2)


func get_spawn_position() -> Vector2:
	var result = $"UnitSpawnPlayer".global_position \
		if get_collision_layer_value(2) \
		else $"UnitSpawnEnemy".global_position
	result.y += randf_range(spawn_range_y.x, spawn_range_y.y)
	return result
