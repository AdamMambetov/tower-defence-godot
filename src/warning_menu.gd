class_name WarningMenu extends Panel


@export var title: String:
	set(value):
		title = value
		if is_instance_valid(title_node):
			title_node.text = title

@export var detail: String:
	set(value):
		detail = value
		if is_instance_valid(detail_node):
			detail_node.text = detail

@export var _title_node_path: NodePath
@onready var title_node: Label = get_node(_title_node_path)
@export var _detail_node_path: NodePath
@onready var detail_node: Label = get_node(_detail_node_path)


func show_menu() -> void:
	visible = true
	grab_focus()


func _on_focus_exited() -> void:
	visible = false
