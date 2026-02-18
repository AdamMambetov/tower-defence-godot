extends Unit


class UnitState:
	const None = ""
	const Walk = "walk"
	const Attack = "attack"
	const WaitAttack = "wait_attack"
	const Death = "death"


const ANIMATIONS_POS_RIGHT = Vector2(-55, -128)
const ANIMATIONS_POS_LEFT = Vector2(-74, -128)

@export var _wait_attack_timer_path: NodePath
@onready var wait_attack_timer: Timer = get_node(_wait_attack_timer_path)


func _ready() -> void:
	super._ready()
	wait_attack_timer.wait_time = attack_speed


func is_move_state() -> bool:
	return unit_state == UnitState.Walk

func is_attack_state() -> bool:
	return unit_state == UnitState.Attack

func action_attack() -> void:
	unit_state = UnitState.Attack

func action_move() -> void:
	unit_state = UnitState.Walk


func _on_set_unit_state(_old: String, new: String) -> void:
	match new:
		UnitState.None:
			if tower_node.tower_state == Tower.TowerState.Defence:
				animations.play(&"idle")
		UnitState.Walk:
			animations.play(&"walk")
		UnitState.Attack:
			animations.play(&"attack")
			await animations.animation_finished
			if unit_state != UnitState.Attack:
				return
			if attack_area.has_overlapping_areas():
				find_nearest_enemy()
			else:
				nearest_enemy = null
			if is_instance_valid(nearest_enemy) and (is_player or tower_node.player_left):
				WS.attack(self.id, nearest_enemy.id)
			unit_state = UnitState.WaitAttack
		UnitState.WaitAttack:
			animations.play(&"idle")
			wait_attack_timer.start()
			await wait_attack_timer.timeout
			if unit_state != UnitState.WaitAttack:
				return
			action_none()
		UnitState.Death:
			animations.play(&"death")
			await animations.animation_finished
			queue_free()

func _on_set_direction(old: Vector2, new: Vector2) -> void:
	super._on_set_direction(old, new)
	if new.x > 0:
		animations.position = ANIMATIONS_POS_RIGHT
	else:
		animations.position = ANIMATIONS_POS_LEFT
