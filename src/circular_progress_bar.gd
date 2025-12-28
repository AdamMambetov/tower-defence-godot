@tool
class_name CircularProgressBar extends Control


signal value_changed(old, new)
signal animation_finished()


@export_range(0.0, 1.0) var value: float = 0.75:
	set(new_value):
		var old = value
		value = clampf(new_value, 0.0, 1.0)
		value_changed.emit(old, value)
		_get_material().set_shader_parameter(&"progress", value)

@export_range(0.01, 0.2) var thickness: float = 0.051:
	set(new_thickness):
		thickness = clampf(new_thickness, 0.01, 0.2)
		_get_material().set_shader_parameter(&"thickness", thickness)

@export var color: Color = Color(0.0, 0.0, 0.0, 0.5):
	set(new_color):
		color = new_color
		_get_material().set_shader_parameter(&"color", color)

@export var test_start_anim = false:
	set(new):
		test_start_anim = new
		if test_start_anim:
			start(3)


func _ready() -> void:
	$ColorRect.material = ShaderMaterial.new()
	$ColorRect.material.shader = preload("res://src/circular_progress_bar.gdshader")
	value = value
	thickness = thickness
	color = color


func _get_material() -> ShaderMaterial:
	return $ColorRect.material as ShaderMaterial


func start(time_in_sec: float = 1.0, reversed: bool = false) -> void:
	value = 1.0 if !reversed else 0.0
	var final_var = 0.0 if !reversed else 1.0
	var tween = get_tree().create_tween()
	tween.tween_property(self, "value", final_var, time_in_sec)
	tween.play()
	await tween.finished
	animation_finished.emit()
