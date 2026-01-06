extends AudioStreamPlayer

var main_menu_track = preload("res://file/music/main_menu.mp3")
var battle_tracks = [
	preload("res://file/music/battle_1.mp3"),
	preload("res://file/music/battle_2.mp3"),
]
var current_battle_track: int
var in_battle = false


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


func _on_finished() -> void:
	if !in_battle:
		return
	
	current_battle_track = (current_battle_track + 1) % battle_tracks.size()
	stream = battle_tracks[current_battle_track]
	play()
