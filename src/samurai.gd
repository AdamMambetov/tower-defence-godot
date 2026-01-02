extends Unit


class UnitState:
	const None = ""
	const Run = "run"
	const Shot = "shot"
	const WaitAttack = "wait_attack"
	const Death = "death"


const ARROW_SCENE = preload("res://scene/arrow.tscn")

@export var _wait_attack_timer_path: NodePath
@onready var wait_attack_timer: Timer = get_node(_wait_attack_timer_path)


func _ready() -> void:
	super._ready()
	wait_attack_timer.wait_time = attack_speed


func is_move_state() -> bool:
	return unit_state == UnitState.Run

func action_attack() -> void:
	unit_state = UnitState.Shot

func action_move() -> void:
	unit_state = UnitState.Run


func _on_set_unit_state(_old: String, new: String) -> void:
	match new:
		UnitState.None:
			if tower_node.tower_state == Tower.TowerState.Defence:
				animations.play(&"idle")
		UnitState.Run:
			animations.play(&"run")
		UnitState.Shot:
			animations.play(&"shot")
			await animations.animation_finished
			if unit_state != UnitState.Shot:
				return
			var arrow = ARROW_SCENE.instantiate()
			arrow.global_position = $ArrowSpawn.global_position
			var distance = attack_collision.shape.size.x
			if attack_area.has_overlapping_areas():
				find_nearest_enemy()
			else:
				nearest_enemy = null
			var to_point: Vector2
			if nearest_enemy is Unit:
				to_point = nearest_enemy.unit_collision.global_position
			elif nearest_enemy is Tower:
				to_point = nearest_enemy.tower_collition.global_position
			else:
				to_point = attack_collision.global_position
				to_point.x += distance / 2
			arrow.update_info({
				id = id,
				distance = distance,
				damage = damage,
				to_point = to_point,
			})
			arrow.is_player = is_player
			get_parent().add_child(arrow)
			unit_state = UnitState.WaitAttack
		UnitState.WaitAttack:
			wait_attack_timer.start()
			await wait_attack_timer.timeout
			if unit_state != UnitState.WaitAttack:
				return
			action_none()
		UnitState.Death:
			animations.play(&"death")
			await animations.animation_finished
			queue_free()
