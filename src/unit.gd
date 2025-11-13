class_name Unit extends Area2D


enum UnitState {
	None,
	Walk,
	Attack,
	WaitAttack,
	Death,
}

@export var speed = 50
@export var damage = 5
@export var is_player: bool
@export var attack_speed = 3.0
@export var health: float = 100.0:
	set(value):
		health = value
		_on_set_health()
var unit_state: UnitState = UnitState.None:
	set(value):
		unit_state = value
		_on_set_unit_state()

@export var shape_cast_path: NodePath
@onready var shape_cast: ShapeCast2D = get_node(shape_cast_path)


func _ready() -> void:
	set_collision_layer_value(2, is_player)
	set_collision_layer_value(3, !is_player)
	set_collision_mask_value(2, !is_player)
	set_collision_mask_value(3, is_player)
	shape_cast.set_collision_mask_value(2, !is_player)
	shape_cast.set_collision_mask_value(3, is_player)
	shape_cast.rotation_degrees = 0 if is_player else -180

func _physics_process(delta: float) -> void:
	if shape_cast.is_colliding():
		for res in shape_cast.collision_result:
			var enemy = res.collider
			if !is_instance_valid(enemy):
				continue
			enemy.health -= damage * delta
			break
	else:
		move_unit(delta)


func _on_set_health() -> void:
	$Label.text = str(int(health))
	if health <= 0:
		queue_free()

func _on_set_unit_state() -> void:
	pass


func update_info(info: Dictionary) -> void:
	speed = info.speed
	damage = info.damage
	health = info.health
	attack_speed = info.attack_speed

func move_unit(delta: float) -> void:
	if is_player:
		position.x += speed * delta 
	else:
		position.x -= speed * delta 
