extends Area2D

@export var speed = 50
@export var damage = 5
@export var is_player: bool
@export var health: float = 100.0:
	set(value):
		health = value
		$Label.text = str(int(health))
		if health <= 0:
			queue_free()


func _ready() -> void:
	set_collision_layer_value(2, is_player)
	set_collision_layer_value(3, !is_player)
	set_collision_mask_value(2, !is_player)
	set_collision_mask_value(3, is_player)
	$ShapeCast2D.set_collision_mask_value(2, !is_player)
	$ShapeCast2D.set_collision_mask_value(3, is_player)
	$ShapeCast2D.rotation_degrees = 0 if is_player else -180

func _physics_process(delta: float) -> void:
	if $ShapeCast2D.is_colliding():
		for res in $ShapeCast2D.collision_result:
			var enemy = res.collider
			if !is_instance_valid(enemy):
				continue
			enemy.health -= damage * delta
			break
	else:
		if is_player:
			position.x += speed * delta 
		else:
			position.x -= speed * delta 


func update_info(info: Dictionary) -> void:
	speed = info.speed
	damage = info.damage
	health = info.health
