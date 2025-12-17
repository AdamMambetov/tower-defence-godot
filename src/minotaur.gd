extends Unit


class UnitState:
	const None = ""
	const Walk = "walk"
	const Attack = "attack"
	const WaitAttack = "wait_attack"
	const Death = "death"


const ANIMATIONS_POS_RIGHT = Vector2(-35, -100)
const ANIMATIONS_POS_LEFT = Vector2(-100, -100)

@export var _animations_path: NodePath
@onready var animations: AnimatedSprite2D = get_node(_animations_path)

@export var wait_attack_timer_path: NodePath
@onready var wait_attack_timer: Timer = get_node(wait_attack_timer_path)

var current_enemy: Node


func _ready() -> void:
	super._ready()
	
	wait_attack_timer.wait_time = attack_speed
	$UnitArea/ProgressBar.max_value = health
	$UnitArea/ProgressBar.value = health

func _physics_process(delta: float) -> void:
	match unit_state:
		UnitState.None:
			if attack_area.has_overlapping_areas():
				var areas = attack_area.get_overlapping_areas()
				for area in areas:
					var enemy = area.get_parent()
					if !is_instance_valid(enemy):
						continue
					if enemy.health <= 0:
						continue
					current_enemy = enemy
					break
				if is_instance_valid(current_enemy):
					unit_state = UnitState.Attack
			else:
				unit_state = UnitState.Walk
		UnitState.Walk:
			if attack_area.has_overlapping_areas():
				unit_state = UnitState.None
				return
			move_unit(delta)


func _on_set_health(_old: float, new: float) -> void:
	$UnitArea/ProgressBar.value = new
	if new <= 0:
		var current_frame = animations \
				.sprite_frames \
				.get_frame_count(animations.animation) - 1
		if animations.frame == current_frame:
			await animations.animation_finished
			await get_tree().physics_frame
		unit_state = UnitState.Death

func _on_set_unit_state(_old: String, new: String) -> void:
	match new:
		UnitState.Walk:
			animations.play(&"walk")
		UnitState.Attack:
			animations.play(&"attack")
			await animations.animation_finished
			if unit_state != UnitState.Attack:
				return
			if is_instance_valid(current_enemy) and is_player:
				WS.attack(self.id, current_enemy.id)
			current_enemy = null
			unit_state = UnitState.WaitAttack
		UnitState.WaitAttack:
			animations.play(&"idle")
			wait_attack_timer.start()
			await wait_attack_timer.timeout
			if unit_state != UnitState.WaitAttack:
				return
			unit_state = UnitState.None
		UnitState.Death:
			animations.play(&"death")
			await animations.animation_finished
			queue_free()

func _on_set_direction(_old: Vector2, new: Vector2) -> void:
	match new:
		Vector2.RIGHT:
			animations.flip_h = false
			animations.position = ANIMATIONS_POS_RIGHT
		Vector2.LEFT:
			animations.flip_h = true
			animations.position = ANIMATIONS_POS_LEFT
