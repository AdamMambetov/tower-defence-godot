@tool
extends Node2D


enum Types  {
	black,
	blue,
	dark_red,
	green,
	pink,
	red,
	violet,
	white,
	yellow,
	yellow_green,
}

var id: int
@export var price: float
@export var health: float = 200.0:
	set(value):
		health = value
		visible = true
		animations.frame = calc_frame(health, 200.0)
		if value <= 0.0:
			health = 0.0
			visible = false
@export var type: Types:
	set(value):
		type = value
		animations.play(Types.keys()[type], 0)
		animations.frame = 2 - size
@export_range(0, 2) var size: int = 2:
	set(value):
		size = value
		animations.play(Types.keys()[type], 0)
		animations.frame = 2 - size

@export var _animations_path: NodePath
@onready var animations: AnimatedSprite2D = get_node(_animations_path)


func _ready() -> void:
	pass


func calc_frame(in_health: float, in_max_health: float) -> int:
	return clamp(3 - int(in_health / in_max_health / 0.33 + 1), 0, 2)

func update_info(info: Dictionary) -> void:
	id = info.id
	type = Types.values()[Types.keys().find(info.name)]
	health = info.health
	size = info["size"]
