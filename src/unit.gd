class_name Unit extends Area2D


var UnitState: Dictionary[String, String]

var id: String
@export var speed = 50
@export var damage = 5
@export var is_player: bool
@export var attack_speed = 3.0
@export var health: float = 100.0:
	set(value):
		var old = health
		health = value
		_on_set_health(old, value)
var unit_state: String = UnitState.None:
	set(value):
		var old = unit_state
		unit_state = value
		_on_set_unit_state(old, value)

@export var shape_cast_path: NodePath
@onready var shape_cast: ShapeCast2D = get_node(shape_cast_path)


func _ready() -> void:
	_init_unit_states()
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


func _init_unit_states() -> void:
	UnitState = {
		None = "none",
		Walk = "walk",
		Attack = "attack",
		WaitAttack = "wait_attack",
		Death = "death",
	}


func _on_set_health(old: float, new: float) -> void:
	$Label.text = str(int(health))
	if health <= 0:
		queue_free()

func _on_set_unit_state(old: String, new: String) -> void:
	pass


func update_info(info: Dictionary) -> void:
	speed = info.speed
	damage = info.damage
	health = info.health
	attack_speed = info.attack_speed
	id = info.id

func move_unit(delta: float) -> void:
	if is_player:
		position.x += speed * delta 
	else:
		position.x -= speed * delta 
