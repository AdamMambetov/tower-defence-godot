extends Node2D


var id: String
@export var speed = 1000
@export var damage = 5
@export var is_player: bool = true
var player_left: bool = false

var direction: Vector2 = Vector2.RIGHT:
	set(value):
		var old = direction
		direction = value
		_on_set_direction(old, value)
var distance: float

@export var _sprite_path: NodePath
@onready var sprite: Sprite2D = get_node(_sprite_path)

@export var _area_path: NodePath
@onready var area_node: Area2D = get_node(_area_path)


func _ready() -> void:
	area_node.set_collision_mask_value(2, !is_player)
	area_node.set_collision_mask_value(3, is_player)
	launch(global_position, end_point)

func _physics_process(delta: float) -> void:
	update_launch(delta)
	
	if area_node.has_overlapping_areas():
		var unit = area_node.get_overlapping_areas()[0].get_parent()
		if is_player or player_left:
			var from_id = id + " " if player_left else id
			GameWS.attack(from_id, unit.id)
		is_launched = false
		queue_free()


func update_info(info: Dictionary) -> void:
	id = info.id
	damage = info.damage
	direction = global_position.direction_to(info.to_point)
	rotation = global_position.angle_to_point(info.to_point)
	end_point = info.to_point
	distance = end_point.distance_to(global_position)


func _on_set_direction(_old: Vector2, new: Vector2) -> void:
	match new:
		Vector2.RIGHT:
			sprite.flip_h = false
		Vector2.LEFT:
			sprite.flip_h = true






var start_point: Vector2
var end_point: Vector2
@export var arc_height: float = 10.0
var duration: float = 0.5
var time_elapsed: float = 0.0
var is_launched: bool = false

func launch(from: Vector2, to: Vector2) -> void:
	start_point = from
	end_point = to
	time_elapsed = 0.0
	duration = (distance - $Area2D/CollisionShape2D.shape.size.x / 2 + 50) / speed
	is_launched = true
	position = start_point

func update_launch(delta: float) -> void:
	if not is_launched:
		return
	
	time_elapsed += delta
	var t = time_elapsed / duration
	
	if t <= 1.0:
		# Квадратичная Bezier кривая с контрольной точкой для создания дуги
		var control_point = Vector2(
			(start_point.x + end_point.x) / 2,
			min(start_point.y, end_point.y) - arc_height
		)
		
		# Формула квадратичной кривой Безье
		position = calculate_bezier_point(t, start_point, control_point, end_point)
		
		# Вычисляем производную для определения направления
		var derivative = calculate_bezier_derivative(t, start_point, control_point, end_point)
		rotation = derivative.angle()
	else:
		# Достигли цели
		is_launched = false
		queue_free()

func calculate_bezier_point(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u = 1.0 - t
	return u * u * p0 + 2 * u * t * p1 + t * t * p2

func calculate_bezier_derivative(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	return 2 * (1 - t) * (p1 - p0) + 2 * t * (p2 - p1)
