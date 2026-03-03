@tool
extends PanelContainer


const ONLINE_COLOR = Color(0.27, 0.63, 0.40)
const OFFLINE_COLOR = Color(0.5, 0.5, 0.5)

@export var is_online: bool:
	set(value):
		if value == is_online:
			return
		is_online = value
		if !is_instance_valid(online_circle):
			return
		online_circle \
			.get_theme_stylebox("panel") \
			.bg_color = ONLINE_COLOR if is_online else OFFLINE_COLOR

@export var username: String = "Друг":
	set(value):
		username = value
		if !is_instance_valid(username_label):
			return
		username_label.text = username

@export var _online_circle_path: NodePath
@onready var online_circle: Panel = get_node(_online_circle_path)

@export var _username_label_path: NodePath
@onready var username_label: Label = get_node(_username_label_path)


func _ready() -> void:
	username_label.text = username
	online_circle \
		.get_theme_stylebox("panel") \
		.bg_color = ONLINE_COLOR if is_online else OFFLINE_COLOR
