class_name GameManager
extends Node2D

## Controls the entire game: 
## Main Menu 
## Networking
## Loading Levels
## User Interface
## This object is the root of the game

static var Instance : GameManager

## TEST BOOLS
@export_subgroup("Debug")
@export var wait_for_player : bool = false
@export var dont_spawn_enemies : bool = false

signal end_game
signal start_lvl_up_sequence(item : Array)
signal end_lvl_up_sequence()

var is_started : bool = false
var is_paused : bool = false:
	set(value):
		is_paused = value
		get_tree().paused = value

var time : float
var players : Array[BaseHero] = []
var local_player : BaseHero

# For selecting cards.
var players_ready : int
var action_selected : bool

var net : NetManager
var spawner : EnemySpawner
var ui : UIManager
var bc # beat controllerx

# XP
var current_xp : int
var max_xp : int # TODO: Change this for a func in futrue


# LVL
const max_lvl : int = 16
var current_lvl : int:
	set(value):
		for x in players:
			x.level_up.emit(value)
		
		current_lvl = value
		if !local_player || !ui : return
		ui.update_lvl_label(value)

func _init() -> void:
	Instance = self
	time = 0
	current_xp = 0
	max_xp = 1
	end_game.connect(on_end_game)

func _process(delta: float) -> void:
	timer_logic(delta)

func start_game():
	time = 0
	is_started = true
	if dont_spawn_enemies: 
		# for testing.
		spawner.custom_spawn("res://ver_1/character/enemy/Dummy/dummy.tscn", Vector2(651,335))
		return
	spawner._start_timer()

func on_end_game():
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

func change_max_xp() -> void:
	# when we have a curve, set max_xp -> curve.y.value or sth
	max_xp = sample(current_lvl)
	ui.update_max_xp(max_xp)

### Card Sequence 
func start_level_up_sequence():
	players_ready = 0
	for player in players:
		# the items for each player could be different
		# lets set it to same for now
		var items = choose_items(player)
		client_level_up.rpc_id(player.id, items)

# Algorithm for choosing actions for level up.
func choose_items(hero : BaseHero) -> Array[String]:
	var item : BaseAction = AOEItem.new()
	var script_name : String = serialize(item)
	return [script_name, script_name, script_name]

# refactor -> pass an  integer instead of an action
func tell_server_client_is_ready(action_name):
	client_selection_ready.rpc_id(1, action_name)

# Process and give item
@rpc("authority", "call_local", "reliable")
func parse_action_card(id : int, _action_name):
	var player : BaseHero = get_player(id)
	var action = deserialize(_action_name) as BaseAction
	
	# Parse item
	if action is BaseItem:
		if !player.has_item(action):
			player.add_item(action)
		else:
			player.upgrade_item(action)
	
	# TODO: Parse ability
	if action is BaseAbility:
		# parse ability
		pass
	action

# Death & Strawberry
func check_alive_players() -> void:
	if !multiplayer.is_server(): return
	for x in players:
		if !x.IS_DEAD:
			return
	# End game, players all dead
	tell_everyone_end_game.rpc()

### RPC Calls
@rpc("call_local", "reliable")
func client_level_up(items : Array):
	is_paused = true
	start_lvl_up_sequence.emit(items)

# run on the server only.
@rpc("call_local", "any_peer")
func client_selection_ready(action_name):
	players_ready += 1
	parse_action_card.rpc(multiplayer.get_remote_sender_id(), action_name)
	
	if players_ready == players.size():
		tell_client_end_card_sequence.rpc()

@rpc("call_local",  "unreliable_ordered")
func tell_client_end_card_sequence():
	is_paused = false
	
	# FIXME: Currently assume that its always an lvl up for card. 
	change_max_xp()
	current_lvl += 1
	end_lvl_up_sequence.emit()

@rpc("call_local", "unreliable_ordered")
func sync_xp_bar(xp):
	ui.update_xp(xp)

@rpc("call_local", "reliable")
func tell_everyone_end_game():
	end_game.emit()

### Helper functions
func is_game_started() -> bool:
	return is_started

func is_game_stopped() -> bool:
	return !is_started || is_paused

# returns player given id
func get_player(id) -> BaseHero:
	for player in players:
		if player.id == id:
			return player
	
	return null 

# turns net ui off and player_ui on
func change_ui():
	ui.show_ui()
	net.hide_ui()


func serialize(action : BaseAction) -> String:
	var rs : String = action.get_script().resource_path
	rs = rs.get_file().get_slice(".", 0)
	return rs

func deserialize(string : String) -> BaseAction:
	# add a check for abilities as well...
	
	var action = load("res://ver_1/actions/items/" + string + ".gd").new() as BaseAction
	return action

func script_name_to_item_scene(string) -> String:
	var filename : String = string.resource_path
	filename = filename.get_file().get_slice(".", 0)
	filename += ".tscn"
	return "res://ver_1/actions/items/" + filename

func sample(x : int) -> int:
	return 100 + (10 * x)
