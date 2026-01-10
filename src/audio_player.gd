extends AudioStreamPlayer


var main_menu_track = preload("res://file/music/main_menu.mp3")
var battle_tracks = [
	preload("res://file/music/battle_1.mp3"),
	preload("res://file/music/battle_2.mp3"),
]
var current_battle_track: int
var in_battle = false

const volume: Dictionary = {
	min = 0.0,
	max = 2.0,
	percent_max = 100.0,
}


func _ready() -> void:
	finished.connect(_on_finished)
	volume_linear = 0.1


func play_main_menu() -> void:
	in_battle = false
	stream = main_menu_track
	play()

func play_battle() -> void:
	in_battle = true
	current_battle_track = randi() % battle_tracks.size()
	stream = battle_tracks[current_battle_track]
	play()

# return  0..100
func get_music_volume() -> float:
	return convert_volume_to_percent(volume_linear)

# value = 0..100
func set_music_volume(value: float) -> void:
	var res = convert_volume_from_percent(value)
	volume_linear = res

func convert_volume_from_percent(value: float) -> float:
	var result = remap(
		value,
		volume.min,
		volume.percent_max,
		volume.min,
		volume.max,
	)
	return clamp(result, volume.min, volume.max)

func convert_volume_to_percent(value: float) -> float:
	var result = remap(
		value,
		volume.min,
		volume.max,
		volume.min,
		volume.percent_max,
	)
	return clamp(result, volume.min, volume.percent_max)


func _on_finished() -> void:
	if !in_battle:
		return
	
	current_battle_track = (current_battle_track + 1) % battle_tracks.size()
	stream = battle_tracks[current_battle_track]
	play()
