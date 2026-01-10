extends Node


enum GameState {
	Menu,
	WaitingGame,
	PlayingGame,
}

enum Route {
	Tower,
	Mine,
}


const units = {
	soldier = preload("res://scene/soldier.tscn"),
	samurai = preload("res://scene/samurai.tscn"),
	minotaur = preload("res://scene/minotaur.tscn"),
	miner = preload("res://scene/miner.tscn"),
	witch = preload("res://scene/witch.tscn"),
}

var game_state: GameState


func get_password(key: String) -> String:
	return Keyring.get_password(
		"godot_tower_defence",
		"credentials",
		key,
	)

func set_password(key: String, value: String) -> void:
	var err = Keyring.set_password(
		"godot_tower_defence",
		"credentials",
		key,
		value
	)
	if err:
		printerr("Keyring {err} key: {key} value: {value}".format({
			err = err,
			key = key,
			value = value,
		}))
