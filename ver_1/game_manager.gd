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
signal start_lvl_up_sequence(item : Array)
signal end_lvl_up_sequence()

var is_started : bool = false
var is_paused : bool = false:
	set(value):
		is_paused = value
		get_tree().paused = value

var time : float

var players : Array[BaseHero] = []

# For selecting cards.
var players_ready : int
var action_selected : bool

var net : NetManager
var spawner : EnemySpawner
var ui : UIManager
var bc # beat controller

# XP
var current_xp : int
var max_xp : int # TODO: Change this for a func in futrue

# LVL
const max_lvl : int = 16
var current_lvl : int

func _init() -> void:
	Instance = self
	time = 0
	current_xp = 0
	max_xp = 10

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

func add_xp(_xp : int):
	# TODO: add client-prediction for future.
	
	# Sanity check
	if !multiplayer.is_server(): return
	current_xp += _xp
	sync_xp_bar.rpc(current_xp)
	
	if current_xp >= max_xp:
		current_xp = current_xp - max_xp
		start_level_up_sequence()

func start_level_up_sequence():
	players_ready = 0
	for player in players:
		var items = choose_items(player)
		client_level_up.rpc_id(player.id, items)

# Algorithm for choosing actions for level up.
func choose_items(hero : BaseHero) -> Array[BaseAction]:
	
	# Lets just return 3 Trebbie Attacks
	var attack = TrebbieAttack.new()
	
	return [attack, attack, attack]

func tell_server_client_is_ready(card : SelectionCard):
	client_selection_ready.rpc_id(1, card)
	pass

### RPC Calls
@rpc("call_local", "reliable")
func client_level_up(items : Array):
	is_paused = true
	start_lvl_up_sequence.emit(items)

@rpc("call_local", "unreliable_ordered")
func sync_xp_bar(xp):
	ui.update_xp(xp)

# run on the server only.
@rpc("call_local", "any_peer")
func client_selection_ready(card):
	players_ready += 1
	parse_action_card(multiplayer.get_remote_sender_id(), card)
	
	if players_ready == players.size():
		tell_client_end_card_sequence.rpc()

@rpc("call_local",  "unreliable_ordered")
func tell_client_end_card_sequence():
	is_paused = false
	end_lvl_up_sequence.emit()

func parse_action_card(id,card):
	pass

### Helper functions
func is_game_started() -> bool:
	return is_started

func is_game_stopped() -> bool:
	return !is_started || is_paused

func change_ui():
	ui.show_ui()
	net.hide_ui()
