class_name Unit extends Node2D


signal destroyed(is_player: bool, unit_id: String)


var id: String
@export var speed = 50
@export var damage = 5
@export var is_player: bool
@export var attack_speed = 3.0
@export var health: float = 100.0:
	set(value):
		var old = health
		health = value
		_on_set_health(old, value)

var unit_state: String:
	set(value):
		if unit_state == value:
			return
		var old = unit_state
		unit_state = value
		_on_set_unit_state(old, value)

var tower_node: Tower

var direction: Vector2 = Vector2.RIGHT:
	set(value):
		var old = direction
		direction = value
		_on_set_direction(old, value)

var nearest_enemy: Node2D = null

@export var _unit_area_path: NodePath
@onready var unit_area: Area2D = get_node(_unit_area_path)

@export var _unit_collision_path: NodePath
@onready var unit_collision: CollisionShape2D = get_node(_unit_collision_path)

@export var _attack_area_path: NodePath
@onready var attack_area: Area2D = get_node(_attack_area_path)

@export var _attack_collision_path: NodePath
@onready var attack_collision: CollisionShape2D = get_node(_attack_collision_path)

@export var _agr_area_path: NodePath
@onready var agr_area: Area2D = get_node(_agr_area_path)

@export var _agr_collision_path: NodePath
@onready var agr_collision: CollisionShape2D = get_node(_agr_collision_path)

@export var _health_bar_path: NodePath
@onready var health_bar: ProgressBar = get_node(_health_bar_path)

@export var _animations_path: NodePath
@onready var animations: AnimatedSprite2D = get_node(_animations_path)


func _ready() -> void:
	attack_area.area_entered.connect(_on_attack_area_area_entered)
	attack_area.area_exited.connect(_on_attack_area_area_exited)
	agr_area.area_entered.connect(_on_agr_area_area_entered)
	agr_area.area_exited.connect(_on_agr_area_area_exited)
	GameWS.new_data_received.connect(_on_GameWS_new_data_recieved)
	tower_node.tower_state_changed.connect(_on_tower_state_changed)
	unit_area.set_collision_layer_value(2, is_player)
	unit_area.set_collision_layer_value(3, !is_player)
	unit_area.set_collision_mask_value(2, !is_player)
	unit_area.set_collision_mask_value(3, is_player)
	attack_area.set_collision_mask_value(2, !is_player)
	attack_area.set_collision_mask_value(3, is_player)
	agr_area.set_collision_mask_value(2, !is_player)
	agr_area.set_collision_mask_value(3, is_player)
	direction = get_default_direction()
	action_move()
	if !is_player:
		var fill_box = StyleBoxFlat.new()
		fill_box.bg_color = Color.RED
		health_bar.add_theme_stylebox_override("fill", fill_box)

func _physics_process(delta: float) -> void:
	match tower_node.tower_state:
		Tower.TowerState.Attack:
			if !is_move_state():
				return
			move_attack(delta)
		Tower.TowerState.Defence:
			if (!is_on_defence_position() or tower_node.has_enemies()) \
					and unit_state.is_empty():
				action_move()
			if !is_move_state():
				return
			
			if tower_node.has_enemies():
				move_attack(delta)
			else:
				move_defence(delta)

func _exit_tree() -> void:
	destroyed.emit(is_player, id)


func update_info(info: Dictionary) -> void:
	speed = info.speed
	damage = info.damage
	health = info.health
	attack_speed = info.attack_speed
	id = info.id
	
	if !is_instance_valid(health_bar):
		health_bar = get_node(_health_bar_path)
	health_bar.max_value = health
	health_bar.value = health

func move_attack(delta: float) -> void:
	direction = get_default_direction()
	if find_nearest_enemy():
		direction = global_position.direction_to(nearest_enemy.global_position)
		direction.x /= 2
		direction.y *= 2
		direction = direction.normalized()
	position += speed * delta * direction

func move_defence(delta: float) -> void:
	if is_on_defence_position():
		direction = get_default_direction()
		action_none()
		return
	var to_position = tower_node.get_defence_position(id)
	direction = global_position.direction_to(to_position)
	if (direction.x > 0 and is_player) \
			or (direction.x < 0 and !is_player):
		if has_enemy_on_attack_distance(tower_node.get_defence_position(id)) and has_enemy_on_attack_distance(global_position):
			action_attack()
			return
	position += speed * delta * direction

func action_none() -> void:
	find_nearest_enemy()
	match tower_node.tower_state:
		Tower.TowerState.Attack:
			if attack_area.has_overlapping_areas():
				action_attack()
			else:
				action_move()
		Tower.TowerState.Defence:
			if (tower_node.has_enemies() and attack_area.has_overlapping_areas()) \
					or (has_enemy_on_attack_distance(tower_node.get_defence_position(id)) and has_enemy_on_attack_distance(global_position)):
				action_attack()
			elif !is_on_defence_position():
				action_move()
			else:
				unit_state = ""

func action_attack() -> void:
	pass

func action_move() -> void:
	pass

func is_move_state() -> bool:
	return false
 
func is_attack_state() -> bool:
	return false

func get_default_direction() -> Vector2:
	if is_player:
		return Vector2.RIGHT
	else:
		return Vector2.LEFT

func find_nearest_enemy() -> bool:
	if !agr_area.has_overlapping_areas():
		nearest_enemy = null
		return false
	var enemies = agr_area.get_overlapping_areas()
	nearest_enemy = enemies[0].get_parent()
	for el in enemies:
		var enemy = el.get_parent()
		var distance = global_position.distance_to(enemy.global_position)
		if distance < global_position.distance_to(nearest_enemy.global_position):
			nearest_enemy = enemy
	return true

func is_on_defence_position() -> bool:
	var to_position = tower_node.get_defence_position(id)
	return global_position.distance_to(to_position) <= 1

func horizontal_distance(pos1: Vector2, pos2: Vector2) -> float:
	return abs(pos1.x - pos2.x)

func has_enemy_on_attack_distance(my_pos: Vector2) -> bool:
	if !find_nearest_enemy():
		return false
	
	var x_sign = 1 if is_player else -1
	my_pos.x += unit_collision.shape.size.x / 2 * x_sign
	
	var enemy_pos = nearest_enemy.global_position
	var enemy_x_sign = 1 if nearest_enemy.is_player else -1
	if nearest_enemy is Unit:
		enemy_pos.x += nearest_enemy.unit_collision.shape.size.x / 2 * enemy_x_sign
	elif nearest_enemy is Tower:
		enemy_pos.x += nearest_enemy.tower_collition.shape.size.x / 2 * enemy_x_sign
	
	var enemy_distance = horizontal_distance(my_pos, enemy_pos)
	var attack_distance = attack_collision.shape.size.x
	return enemy_distance <= attack_distance


func _on_set_health(old: float, new: float) -> void:
	if !is_instance_valid(health_bar):
		health_bar = get_node(_health_bar_path)
	health_bar.value = new
	if new <= 0:
		var last_frame = animations \
				.sprite_frames \
				.get_frame_count(animations.animation) - 1
		if animations.frame == last_frame \
				and animations.is_playing() \
				and is_attack_state():
			await animations.animation_finished
			await get_tree().physics_frame
		unit_state = "death"
		unit_collision.disabled = true

func _on_set_unit_state(old: String, new: String) -> void:
	prints(id, old, new)

func _on_set_direction(old: Vector2, new: Vector2) -> void:
	if !is_instance_valid(attack_collision):
		attack_collision = get_node(_attack_collision_path)
	if !is_instance_valid(unit_collision):
		unit_collision = get_node(_unit_collision_path)
	if !is_instance_valid(agr_collision):
		agr_collision = get_node(_agr_collision_path)
	if !is_instance_valid(animations):
		animations = get_node(_animations_path)
	
	animations.flip_h = new.x < 0
	attack_collision.position.x = attack_collision.shape.size.x / 2 * direction.x \
			+ unit_collision.shape.size.x / 2 * direction.x
	agr_collision.position.x = agr_collision.shape.size.x / 2 * direction.x \
			+ unit_collision.shape.size.x / 2 * direction.x

func _on_GameWS_new_data_recieved(result: Dictionary) -> void:
	if !result.has("attacked_units"):
		return
	if !result.attacked_units.has(id):
		return
	
	if result.type == "attack":
		health = result.attacked_units.get(id)

func _on_tower_state_changed(old: String, new: String) -> void:
	if unit_state.is_empty():
		action_move()

func _on_attack_area_area_entered(area: Area2D) -> void:
	find_nearest_enemy()
	var is_tower_state_attack = tower_node.tower_state == Tower.TowerState.Attack
	if (is_tower_state_attack or tower_node.has_enemies()) \
			and is_move_state():
		action_none()
	if unit_state.is_empty():
		action_attack()

func _on_attack_area_area_exited(area: Area2D) -> void:
	find_nearest_enemy()

func _on_agr_area_area_entered(area: Area2D) -> void:
	find_nearest_enemy()

func _on_agr_area_area_exited(area: Area2D) -> void:
	find_nearest_enemy()
