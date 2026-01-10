extends Unit


class UnitState:
	const None = ""
	const Run = "run"
	const Attack = "attack"
	const WaitAttack = "wait_attack"
	const Death = "death"


@export var AnimationPos: Dictionary[String, Vector2]

@export var _wait_attack_timer_path: NodePath
@onready var wait_attack_timer: Timer = get_node(_wait_attack_timer_path)


func _ready() -> void:
	super._ready()
	wait_attack_timer.wait_time = attack_speed


func is_move_state() -> bool:
	return unit_state == UnitState.Run

func is_attack_state() -> bool:
	return unit_state == UnitState.Attack

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
			animations.position = AnimationPos.Run
			animations.play(&"run")
		UnitState.Attack:
			animations.position = AnimationPos.Charge
			animations.play(&"charge")
			await animations.animation_finished
			animations.play(&"charge")
			await animations.animation_finished
			
			if direction.x > 0:
				animations.position = AnimationPos.AttackRight
			else:
				animations.position = AnimationPos.AttackLeft
			
			animations.play(&"attack")
			await animations.animation_finished
			if unit_state != UnitState.Attack:
				return
			if is_player:
				var areas = attack_area.get_overlapping_areas()
				var enemy_ids = []
				for area in areas:
					var enemy = area.get_parent()
					if !is_instance_valid(enemy):
						continue
					if enemy.health <= 0:
						continue
					enemy_ids.push_back(enemy.id)
				WS.attack(self.id, enemy_ids)
			unit_state = UnitState.WaitAttack
		UnitState.WaitAttack:
			animations.position = AnimationPos.Idle
			animations.play(&"idle")
			wait_attack_timer.start()
			await wait_attack_timer.timeout
			if unit_state != UnitState.WaitAttack:
				return
			action_none()
		UnitState.Death:
			animations.position = AnimationPos.Idle
			animations.play(&"death")
			await animations.animation_finished
			queue_free()
