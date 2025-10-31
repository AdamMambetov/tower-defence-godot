extends Area2D


var health: float = 100:
	set(value):
		health = value
		if health <= 0.0:
			health = 0.0
		$PlayerHealthBar.value = health


func _ready() -> void:
	get_collision_layer_value(2)


func get_spawn_position() -> Vector2:
	return $"UnitSpawnPlayer".global_position \
		if get_collision_layer_value(2) \
		else $"UnitSpawnEnemy".global_position
