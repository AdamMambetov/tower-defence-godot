extends Unit


@export var animated_sprite_path: NodePath
@onready var animated_sprite: AnimatedSprite2D = get_node(animated_sprite_path)

@export var wait_attack_timer_path: NodePath
@onready var wait_attack_timer: Timer = get_node(wait_attack_timer_path)

const SOLDIER_ATTACK = &"attack_01"
const ARCHER_ATTACK = &"shoot"

# if false unit is soldier else archer
@export var is_archer = false
var current_enemy: Node


func _ready() -> void:
	super._ready()
	Api.connect("new_data_recived", _on_Api_new_data_recieved)
	
	wait_attack_timer.wait_time = attack_speed
	$ProgressBar.max_value = health
	$ProgressBar.value = health
	
	animated_sprite.flip_h = !is_player
	animated_sprite.play("walk")
	await get_tree().create_timer(0.1).timeout
	animated_sprite.play(SOLDIER_ATTACK)

func _physics_process(delta: float) -> void:
	match unit_state:
		UnitState.None:
			if shape_cast.is_colliding():
				for res in shape_cast.collision_result:
					var enemy = res.collider
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
			if shape_cast.is_colliding():
				unit_state = UnitState.None
				return
			move_unit(delta)


func _on_set_health(_old: float, new: float) -> void:
	$ProgressBar.value = new
	if new <= 0:
		unit_state = UnitState.Death

func _on_set_unit_state(_old: String, new: String) -> void:
	match new:
		UnitState.Walk:
			animated_sprite.play("walk")
		UnitState.Attack:
			animated_sprite.play(ARCHER_ATTACK if is_archer else SOLDIER_ATTACK)
			await animated_sprite.animation_finished
			if unit_state != UnitState.Attack:
				return
			if is_instance_valid(current_enemy) and is_player:
				Api.attack(self.id, current_enemy.id)
				#if current_enemy.health <= 0:
					#current_enemy = null
					#unit_state = UnitState.None
					#return
			current_enemy = null
			unit_state = UnitState.WaitAttack
		UnitState.WaitAttack:
			animated_sprite.play("idle")
			wait_attack_timer.start()
			await wait_attack_timer.timeout
			if unit_state != UnitState.WaitAttack:
				return
			unit_state = UnitState.None
		UnitState.Death:
			animated_sprite.play("death")
			await animated_sprite.animation_finished
			queue_free()

func _on_Api_new_data_recieved(result: Dictionary) -> void:
	if !result.has(id):
		return
	
	if result.type == "attack":
		health = result.get(id)

func _on_animations_animation_finished() -> void:
	print("animation finished")

func _on_animations_animation_changed() -> void:
	print("animation changed")
