extends Node


enum GameState {
	Menu,
	WaitingGame,
	PlayingGame,
}


const units = {
	knight = preload("res://scene/soldier.tscn"),
	archer = preload("res://scene/soldier.tscn"),
}

var game_state: GameState
