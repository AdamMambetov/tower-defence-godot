extends Node


enum GameState {
	Menu,
	WaitingGame,
	PlayingGame,
}

var access: String
var game_state: GameState
