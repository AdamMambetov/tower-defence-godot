extends Unit


class UnitState:
	const None = ""
	const Walk = "walk"
	const Attack = "attack"


const ANIMATIONS_POS_RIGHT = Vector2(-17, -30)
const ANIMATIONS_POS_LEFT = Vector2(-34, -30)

var current_ore: Node = null
var route: Global.Route = Global.Route.Mine:
	set(value):
		route = value
		update_direction()
var max_bag_capacity: float = 0
var bag_capacity: float = 0:
	set(value):
		bag_capacity = value
		$ProgressBar.value = bag_capacity
		if bag_capacity == max_bag_capacity:
			route = Global.Route.Tower

@export var _animations_path: NodePath
@onready var animations: AnimatedSprite2D = get_node(_animations_path)


func _ready() -> void:
	update_direction()

func _physics_process(delta: float) -> void:
	match unit_state:
		UnitState.None:
			if attack_area.has_overlapping_areas():
				var areas = attack_area.get_overlapping_areas()
				for area in areas:
					# if tower
					if area.get_collision_layer_value(4):
						var tower = area.get_parent()
						if route != Global.Route.Tower or !tower.is_player:
							move_unit(delta)
							unit_state = UnitState.Walk
							continue
						WS.socket.send_text(JSON.stringify({
							type = "sell_ore",
							miner = id,
						}))
						bag_capacity = 0
						route = Global.Route.Mine
					# if ore
					if area.get_collision_layer_value(5):
						var ore = area.get_parent()
						if route != Global.Route.Mine:
							continue
						if !is_instance_valid(ore):
							continue
						if ore.health <= 0:
							continue
						current_ore = ore
						unit_state = UnitState.Attack
						break
					# if teleport
					if area.get_collision_layer_value(6):
						move_unit(delta)
						unit_state = UnitState.Walk
						continue
			else:
				unit_state = UnitState.Walk
		UnitState.Walk:
			if attack_area.has_overlapping_areas():
				unit_state = UnitState.None
				return
			move_unit(delta)


func update_info(info: Dictionary) -> void:
	super.update_info(info)
	max_bag_capacity = info.max_bag_capacity
	$ProgressBar.max_value = max_bag_capacity
	bag_capacity = info.bag_capacity
	

func update_direction() -> void:
	match route:
		Global.Route.Tower:
			direction = Vector2.RIGHT
		Global.Route.Mine:
			direction = Vector2.LEFT


func _on_set_unit_state(_old: String, new: String) -> void:
	match new:
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
			unit_state = UnitState.None

func _on_set_direction(old: Vector2, new: Vector2) -> void:
	super._on_set_direction(old, new)
	match new:
		Vector2.RIGHT:
			animations.flip_h = false
			animations.position = ANIMATIONS_POS_RIGHT
		Vector2.LEFT:
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
