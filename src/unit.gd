class_name Unit extends Node2D


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
var unit_state: String:
	set(value):
		var old = unit_state
		unit_state = value
		_on_set_unit_state(old, value)

@export var _unit_area_path: NodePath
@onready var unit_area: Area2D = get_node(_unit_area_path)
@export var _attack_area_path: NodePath
@onready var attack_area: Area2D = get_node(_attack_area_path)
@export var _attack_collision_path: NodePath
@onready var attack_collision: CollisionShape2D = get_node(_attack_collision_path)


func _ready() -> void:
	_init_unit_states()
	unit_area.set_collision_layer_value(2, is_player)
	unit_area.set_collision_layer_value(3, !is_player)
	unit_area.set_collision_mask_value(2, !is_player)
	unit_area.set_collision_mask_value(3, is_player)
	attack_area.set_collision_mask_value(2, !is_player)
	attack_area.set_collision_mask_value(3, is_player)
	attack_collision.position.x = attack_collision.shape.size.x / 2
	attack_collision.position.x *= -1 if !is_player else 1

func _physics_process(delta: float) -> void:
	if unit_area.has_overlapping_areas():
		var areas = unit_area.get_overlapping_areas()
		for area in areas:
			var enemy = area.get_parent()
			if !is_instance_valid(enemy):
				continue
			enemy.health -= damage * delta
			break
	else:
		move_unit(delta)


func _init_unit_states() -> void:
	UnitState = {
		None = "",
		Walk = "walk",
		Attack = "attack",
		WaitAttack = "wait_attack",
		Death = "death",
	}


func _on_set_health(old: float, new: float) -> void:
	prints(id, old, new)
	$UnitArea/Label.text = str(int(new))
	if new <= 0:
		queue_free()

func _on_set_unit_state(old: String, new: String) -> void:
	prints(id, old, new)


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
