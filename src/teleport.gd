extends Node2D


enum Direction {
	Left,
	Right,
}

@export var route: Global.Route
@export var out_direction: Direction


func teleport(unit: Node) -> void:
	unit.direction = _get_out_direction()
	unit.global_position = global_position

func _get_out_direction() -> Vector2:
	match out_direction:
		Direction.Left:
			return Vector2.LEFT
		Direction.Right:
			return Vector2.RIGHT
	return Vector2.ZERO

func _on_area_2d_area_entered(area: Area2D) -> void:
	var unit = area.get_parent()
	for el in get_tree().get_nodes_in_group(&"teleports"):
		if el == self:
			continue
		if el.route == unit.route:
			el.teleport(unit)
			return
