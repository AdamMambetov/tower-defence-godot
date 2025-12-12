class_name Unit extends Node2D


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

var direction: Vector2 = Vector2.RIGHT:
	set(value):
		var old = direction
		direction = value
		_on_set_direction(old, value)

@export var _unit_area_path: NodePath
@onready var unit_area: Area2D = get_node(_unit_area_path)

@export var _attack_area_path: NodePath
@onready var attack_area: Area2D = get_node(_attack_area_path)

@export var _attack_collision_path: NodePath
@onready var attack_collision: CollisionShape2D = get_node(_attack_collision_path)


func _ready() -> void:
	unit_area.set_collision_layer_value(2, is_player)
	unit_area.set_collision_layer_value(3, !is_player)
	unit_area.set_collision_mask_value(2, !is_player)
	unit_area.set_collision_mask_value(3, is_player)
	attack_area.set_collision_mask_value(2, !is_player)
	attack_area.set_collision_mask_value(3, is_player)
	direction = Vector2.RIGHT if is_player else Vector2.LEFT
	attack_collision.position.x = attack_collision.shape.size.x / 2 * direction.x

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


func _on_set_health(old: float, new: float) -> void:
	prints(id, old, new)
	$UnitArea/Label.text = str(int(new))
	if new <= 0:
		queue_free()

func _on_set_unit_state(old: String, new: String) -> void:
	prints(id, old, new)

func _on_set_direction(old: Vector2, new: Vector2) -> void:
	prints(id, old, new)


func update_info(info: Dictionary) -> void:
	speed = info.speed
	damage = info.damage
	health = info.health
	attack_speed = info.attack_speed
	id = info.id

func move_unit(delta: float) -> void:
	position += speed * delta * direction
