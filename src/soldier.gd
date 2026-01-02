extends Unit


class UnitState:
	const None = ""
	const Run = "run"
	const Attack = "attack"
	const WaitAttack = "wait_attack"
	const Death = "death"


const ATTACKS = [&"attack_1", &"attack_2", &"attack_3"]
const ANIMATIONS_POS_RIGHT = Vector2(-35, -128)
const ANIMATIONS_POS_LEFT = Vector2(-100, -128)

@export var _wait_attack_timer_path: NodePath
@onready var wait_attack_timer: Timer = get_node(_wait_attack_timer_path)


func _ready() -> void:
	super._ready()
	wait_attack_timer.wait_time = attack_speed


func is_move_state() -> bool:
	return unit_state == UnitState.Run

func action_attack() -> void:
	unit_state = UnitState.Attack

func action_move() -> void:
	unit_state = UnitState.Run


func _on_set_unit_state(_old: String, new: String) -> void:
	match new:
		UnitState.None:
			if tower_node.tower_state == Tower.TowerState.Defence:
				animations.play(&"idle")
		UnitState.Run:
			animations.play(&"run")
		UnitState.Attack:
			animations.play(ATTACKS[ATTACKS.find(animations.animation) + 1])
			await animations.animation_finished
			if unit_state != UnitState.Attack:
				return
			if attack_area.has_overlapping_areas():
				find_nearest_enemy()
			else:
				nearest_enemy = null
			if is_instance_valid(nearest_enemy) and is_player:
				WS.attack(self.id, nearest_enemy.id)
			if animations.animation == ATTACKS.back():
				unit_state = UnitState.WaitAttack
			else:
				action_none()
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
