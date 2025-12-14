extends Unit


class UnitState:
	const None = ""
	const Run = "run"
	const Attack = "attack"
	const WaitAttack = "wait_attack"
	const Death = "death"


@export var AnimationPos: Dictionary[String, Vector2]

@export var _animations_path: NodePath
@onready var animations: AnimatedSprite2D = get_node(_animations_path)

@export var wait_attack_timer_path: NodePath
@onready var wait_attack_timer: Timer = get_node(wait_attack_timer_path)


func _ready() -> void:
	super._ready()
	WS.new_data_received.connect(_on_WS_new_data_recieved)
	
	wait_attack_timer.wait_time = attack_speed
	$UnitArea/ProgressBar.max_value = health
	$UnitArea/ProgressBar.value = health

func _physics_process(delta: float) -> void:
	match unit_state:
		UnitState.None:
			if attack_area.has_overlapping_areas():
				var find_enemy = false
				var areas = attack_area.get_overlapping_areas()
				for area in areas:
					var enemy = area.get_parent()
					if !is_instance_valid(enemy):
						continue
					if enemy.health <= 0:
						continue
					find_enemy = true
					break
				if find_enemy:
					unit_state = UnitState.Attack
			else:
				unit_state = UnitState.Run
		UnitState.Run:
			if attack_area.has_overlapping_areas():
				unit_state = UnitState.None
				return
			move_unit(delta)


func _on_set_health(_old: float, new: float) -> void:
	$SoldierArea/ProgressBar.value = new
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
		UnitState.Run:
			animations.position = AnimationPos.Run
			animations.play(&"run")
		UnitState.Attack:
			animations.position = AnimationPos.Charge
			animations.play(&"charge")
			await animations.animation_finished
			animations.play(&"charge")
			await animations.animation_finished
			
			match direction:
				Vector2.RIGHT:
					animations.position = AnimationPos.AttackRight
				Vector2.LEFT:
					animations.position = AnimationPos.AttackLeft
			animations.play(&"attack")
			await animations.animation_finished
			if unit_state != UnitState.Attack:
				return
			if is_player:
				var areas = attack_area.get_overlapping_areas()
				for area in areas:
					var enemy = area.get_parent()
					if !is_instance_valid(enemy):
						continue
					if enemy.health <= 0:
						continue
					WS.attack(self.id, enemy.id)
			unit_state = UnitState.WaitAttack
		UnitState.WaitAttack:
			animations.position = AnimationPos.Idle
			animations.play(&"idle")
			wait_attack_timer.start()
			await wait_attack_timer.timeout
			if unit_state != UnitState.WaitAttack:
				return
			unit_state = UnitState.None
		UnitState.Death:
			animations.position = AnimationPos.Idle
			animations.play(&"death")
			await animations.animation_finished
			queue_free()

func _on_WS_new_data_recieved(result: Dictionary) -> void:
	if !result.has(id):
		return
	
	if result.type == "attack":
		health = result.get(id)

func _on_set_direction(_old: Vector2, new: Vector2) -> void:
	match new:
		Vector2.RIGHT:
			animations.flip_h = false
		Vector2.LEFT:
			animations.flip_h = true
