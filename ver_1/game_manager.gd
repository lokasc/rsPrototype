class_name GameManager
extends Node2D

## Controls the entire game: 
## Main Menu 
## Networking
## Loading Levels
## User Interface
## This object is the root of the game

static var Instance : GameManager

#perhaps add signals for on_start_game, on_end_game, on_blah_blah_blah

var is_started : bool = false
var is_paused : bool = false
var time : float

var players : Array[BaseHero] = []

var net : NetManager
var spawner : EnemySpawner
var ui # ui manager 
var bc # beat controller

func _init() -> void:
	Instance = self
	time = 0

func _process(delta: float) -> void:
	timer_logic(delta)

func start_game():
	time = 0
	is_started = true
	spawner._start_timer()

func end_game():
	is_started = false

func timer_logic(delta):
	if is_game_stopped() : return
	time += delta

func add_player_to_list(new_player : BaseHero):
	players.append(new_player)
	return 


### Helper functions
func is_game_started() -> bool:
	return is_started

func is_game_stopped() -> bool:
	return !is_started || is_paused 
