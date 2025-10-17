extends Control

@export var speed: float = 200.0 # скорость вращения (в градусах/сек)
@export var arc_length: float = 270.0 # длина дуги
@export var color: Color = Color(0.2, 0.7, 1.0) # цвет дуги
@export var thickness: float = 6.0 # толщина линии

var angle: float = 0.0 # текущий угол поворота

func _ready() -> void:
	# чтобы центр совпадал с центром контрола
	set_process(true)

func _process(delta: float) -> void:
	angle += speed * delta
	if angle > 360.0:
		angle -= 360.0
	queue_redraw()

func _draw() -> void:
	# вычисляем центр и радиус
	var radius = min(size.x, size.y) / 2 - thickness
	var center = size / 2

	# определяем углы начала и конца дуги
	var from_angle = deg_to_rad(angle)
	var to_angle = from_angle + deg_to_rad(arc_length)

	# рисуем дугу
	draw_arc(center, radius, from_angle, to_angle, 48, color, thickness)
