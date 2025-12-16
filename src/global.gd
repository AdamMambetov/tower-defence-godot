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
}

var game_state: GameState
