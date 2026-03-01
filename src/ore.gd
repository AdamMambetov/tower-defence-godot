@tool
class_name Ore extends Node2D


signal ore_clicked(ore: Ore)


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


var id: String
@export var price: float
@export var max_health: float = 200.0
@export var health: float = 200.0:
	set(value):
		health = value
		animations.frame = calc_frame(health, max_health)
		if value <= 0.0:
			queue_free()
		$ProgressBar.value = health
@export var type: Types:
	set(value):
		type = value
		if !is_instance_valid(animations):
			init_animations()
		animations.play(Types.keys()[type], 0)
		animations.frame = 2 - size
@export_range(0, 2) var size: int = 2:
	set(value):
		size = value
		if !is_instance_valid(animations):
			init_animations()
		animations.play(Types.keys()[type], 0)
		animations.frame = 2 - size

var is_pressed: bool = false

@export var _animations_path: NodePath
@onready var animations: AnimatedSprite2D = get_node(_animations_path)

@export var _selection_anim_path: NodePath
@onready var selection_anim: AnimatedSprite2D = get_node(_selection_anim_path)


func _ready() -> void:
	GameWS.new_data_received.connect(_on_GameWS_new_data_recieved)
	stop_select_anim()


func calc_frame(in_health: float, in_max_health: float) -> int:
	return clamp(3 - int(in_health / in_max_health / 0.33 + 1), 0, 2)

func update_info(info: Dictionary) -> void:
	id = info.id
	type = Types.values()[Types.keys().find(info.name)]
	max_health = info.health
	$ProgressBar.max_value = max_health
	health = info.health
	size = info["size"]

func init_animations() -> void:
	animations = get_node(_animations_path)

func play_select_anim() -> void:
	selection_anim.visible = true
	selection_anim.play(&"select")

func stop_select_anim() -> void:
	selection_anim.visible = false
	selection_anim.stop()

func _on_GameWS_new_data_recieved(result: Dictionary) -> void:
	if result.type != "attack_ore":
		return
	if !result.has(id):
		return
	health = result[id]


func _on_area_2d_input_event(
		_viewport: Node,
		event: InputEvent,
		_shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			is_pressed = true
		elif !event.pressed and is_pressed:
			is_pressed = false
			ore_clicked.emit(self)

func _on_area_2d_mouse_exited() -> void:
	is_pressed = false
