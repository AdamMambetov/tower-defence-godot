extends Node2D


var id: String
@export var speed = 1000
@export var damage = 5
@export var is_player: bool = true

var direction: Vector2 = Vector2.RIGHT:
	set(value):
		var old = direction
		direction = value
		_on_set_direction(old, value)

@export var _sprite_path: NodePath
@onready var sprite: Sprite2D = get_node(_sprite_path)

@export var _area_path: NodePath
@onready var area_node: Area2D = get_node(_area_path)


func _ready() -> void:
	area_node.set_collision_mask_value(2, !is_player)
	area_node.set_collision_mask_value(3, is_player)
	direction = Vector2.RIGHT if is_player else Vector2.LEFT
	$LifeTimeTimer.start()

func _physics_process(delta: float) -> void:
	position += speed * delta * direction
	
	if area_node.has_overlapping_areas():
		var unit = area_node.get_overlapping_areas()[0].get_parent()
		WS.attack(id, unit.id)
		queue_free()


func update_info(info: Dictionary) -> void:
	id = info.id
	damage = info.damage
	$LifeTimeTimer.wait_time = (info.distance - $Area2D/CollisionShape2D.shape.size.x / 2 + 50) / speed


func _on_set_direction(_old: Vector2, new: Vector2) -> void:
	match new:
		Vector2.RIGHT:
			sprite.flip_h = false
		Vector2.LEFT:
			sprite.flip_h = true

func _on_life_time_timer_timeout() -> void:
	queue_free()
