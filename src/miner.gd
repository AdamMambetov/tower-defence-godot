class_name Miner extends Unit


class UnitState:
	const None = ""
	const Idle = "idle"
	const Walk = "walk"
	const Attack = "attack"


const ANIMATIONS_POS_RIGHT = Vector2(-17, -48)
const ANIMATIONS_POS_LEFT = Vector2(-34, -48)

var current_ore: Ore = null
var selected_ore: Ore = null:
	set(value):
		if is_instance_valid(selected_ore):
			selected_ore.stop_select_anim()
		selected_ore = value
var route: Global.Route = Global.Route.Mine
var max_bag_capacity: float = 0
var bag_capacity: float = 0:
	set(value):
		bag_capacity = value
		$ProgressBar.value = bag_capacity
		if bag_capacity == max_bag_capacity:
			route = Global.Route.Tower
			unit_state = UnitState.Walk
var in_mine: bool = false
var is_pressed: bool = false

@export var _selection_anim_path: NodePath
@onready var selection_anim: AnimatedSprite2D = get_node(_selection_anim_path)


func _ready() -> void:
	WS.new_data_received.connect(_on_WS_new_data_recieved)
	attack_area.area_entered.connect(_on_attack_area_area_entered)
	unit_state = UnitState.Idle
	direction = get_default_direction()
	stop_select_anim()

func _physics_process(delta: float) -> void:
	match unit_state:
		UnitState.Idle:
			if !get_tree().get_nodes_in_group(&"ore").is_empty():
				unit_state = UnitState.Walk
		UnitState.Walk:
			move_attack(delta)


func move_attack(delta: float) -> void:
	direction = get_default_direction()
	if route == Global.Route.Mine and in_mine:
		if find_nearest_enemy():
			direction = global_position.direction_to(nearest_enemy.global_position)
			direction.x /= 2
			direction.y *= 2
			direction = direction.normalized()
		else:
			route = Global.Route.Tower
			direction = get_default_direction()
	position += speed * delta * direction

func update_info(info: Dictionary) -> void:
	super.update_info(info)
	max_bag_capacity = info.max_bag_capacity
	$ProgressBar.max_value = max_bag_capacity
	bag_capacity = info.bag_capacity

func get_default_direction() -> Vector2:
	match route:
		Global.Route.Tower:
			direction = Vector2.RIGHT
			agr_collision.disabled = true
		Global.Route.Mine:
			direction = Vector2.LEFT
			agr_collision.disabled = false
	return direction

func action_none() -> void:
	unit_state = UnitState.None
	find_nearest_enemy()
	var areas = attack_area.get_overlapping_areas()
	for area in areas:
		_on_attack_area_area_entered(area)
	if unit_state == UnitState.None:
		action_move()

func action_move() -> void:
	unit_state = UnitState.Walk

func find_nearest_enemy() -> bool:
	if is_instance_valid(selected_ore):
		nearest_enemy = selected_ore
		return true
	if agr_area.has_overlapping_areas():
		var enemies = agr_area.get_overlapping_areas()
		nearest_enemy = enemies[0].get_parent()
		for el in enemies:
			var enemy = el.get_parent()
			var distance = global_position.distance_to(enemy.global_position)
			if distance < global_position.distance_to(nearest_enemy.global_position):
				nearest_enemy = enemy
	else:
		var ores = get_tree().get_nodes_in_group(&"ore")
		if ores.is_empty():
			nearest_enemy = null
			return false
		nearest_enemy = ores[0]
		for ore in ores:
			var ore_distance = global_position.distance_to(ore.global_position)
			var nearest_distance = global_position.distance_to(nearest_enemy.global_position)
			if ore_distance < nearest_distance:
				nearest_enemy = ore
	return true

func play_select_anim() -> void:
	selection_anim.visible = true
	selection_anim.play(&"select")
	if is_instance_valid(selected_ore):
		selected_ore.play_select_anim()

func stop_select_anim() -> void:
	selection_anim.visible = false
	selection_anim.stop()
	if is_instance_valid(selected_ore):
		selected_ore.stop_select_anim()


func _on_set_unit_state(_old: String, new: String) -> void:
	match new:
		UnitState.Idle:
			animations.play(&"idle")
		UnitState.Walk:
			animations.play(&"walk")
		UnitState.Attack:
			animations.play(&"attack")
			await animations.animation_finished
			if unit_state != UnitState.Attack:
				return
			if is_instance_valid(current_ore):
				WS.socket.send_text(JSON.stringify({
					type = "attack_ore",
					from = self.id,
					to = current_ore.id,
				}))
			current_ore = null
			action_none()

func _on_set_direction(old: Vector2, new: Vector2) -> void:
	super._on_set_direction(old, new)
	agr_collision.position = Vector2.ZERO
	if direction.x > 0:
		animations.flip_h = false
		animations.position = ANIMATIONS_POS_RIGHT
	else:
		animations.flip_h = true
		animations.position = ANIMATIONS_POS_LEFT

func _on_set_health(_old: float, _new: float) -> void:
	return

func _on_WS_new_data_recieved(result: Dictionary) -> void:
	if result.type != "attack_ore":
		return
	if !result.has(id):
		return
	bag_capacity = result[id]

func _on_attack_area_area_entered(area: Area2D) -> void:
	var other = area.get_parent()
	if other is Ore and route == Global.Route.Mine:
		if !is_instance_valid(selected_ore) \
				or selected_ore == other:
			current_ore = other
			unit_state = UnitState.Attack
	if other is Tower and route == Global.Route.Tower:
		if !other.is_player:
			return
		WS.socket.send_text(JSON.stringify({
			type = "sell_ore",
			miner = id,
		}))
		if get_tree().get_nodes_in_group(&"ore").is_empty():
			unit_state = UnitState.Idle
		bag_capacity = 0
		route = Global.Route.Mine

func _on_selection_area_input_event(
		_viewport: Node,
		event: InputEvent,
		_shape_idx: int,
) -> void:
	if !in_mine:
		return
	
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			is_pressed = true
		elif !event.pressed and is_pressed:
			is_pressed = false
			tower_node.selected_miner = self

func _on_selection_area_mouse_exited() -> void:
	is_pressed = false
