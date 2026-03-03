@tool
extends PanelContainer

signal on_accept(request_node: Node, user_name: String)
signal on_reject(request_node: Node, user_name: String)

@export var username: String = "Друг":
	set(value):
		username = value
		if !is_instance_valid(username_label):
			return
		username_label.text = username

@export var _username_label_path: NodePath
@onready var username_label: Label = get_node(_username_label_path)


func _ready() -> void:
	username_label.text = username


func enable_buttons() -> void:
	$HBoxContainer/AcceptButton.disabled = false
	$HBoxContainer/RejectButton.disabled = false

func disable_buttons() -> void:
	$HBoxContainer/AcceptButton.disabled = true
	$HBoxContainer/RejectButton.disabled = true


func _on_accept_button_pressed() -> void:
	on_accept.emit(self, username)

func _on_reject_button_pressed() -> void:
	on_reject.emit(self, username)
