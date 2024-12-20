class_name GameManager
extends Node2D

## Controls the entire game_loop:

static var Instance : GameManager

var is_host : bool # this var is so that we can see in testing. 

## TEST BOOLS
@export_subgroup("Debug")
@export var dont_spawn_enemies : bool = false
@export var no_music : bool = false
@export var spawn_dummy : bool = false
@export var spawn_boss : bool = false
@export var quick_leveling : bool = false
@export var infinite_health : bool = false

@export_subgroup("References")
@export var map : Node2D
@export var waiting_lobby : WaitingLobby

@export_category("Game Settings")
@export var action_list : ActionResource

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

# For selecting characters
var players_selection_ready : int
var char_selected : bool = false

# For game state
var is_boss_battle = false

var net : NetManager
var spawner : EnemySpawner
var ui : UIManager
var bc : BeatController
var vfx : VFXManager

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

# Reseting the game.
@onready var gm_scene = preload("res://ver_1/game/main/game_manager.tscn")
var current_gm_scene

#region Godot Functions
func _init() -> void:
	Instance = self
	time = 0
	current_xp = 0
	max_xp = 30
	end_game.connect(on_end_game)

func _ready() -> void:
	get_parent().reset()
	current_gm_scene = self
	map.visible = false
	waiting_lobby.visible = true
	
	if no_music:
		AudioServer.set_bus_mute(0, true)
	if quick_leveling:
		max_xp = 1

func _process(delta: float) -> void:
	timer_logic(delta)
#endregion"res://ver_1/character/enemy/Shooter/shooter.tscn"

#region character_selection
# this func connected by signals from UI
func on_character_selected(character_index : int):
	if char_selected: return
	char_selected = true
	ui.hide_character_select()
	ui.show_player_ui()
	
	if !multiplayer.is_server():
		cts_request_spawn.rpc_id(1, character_index)
	else:
		net.add_player(multiplayer.get_unique_id(), character_index)

@rpc("any_peer", "reliable")
func cts_request_spawn(index : int):
	net.add_player(multiplayer.get_remote_sender_id(), index)
#endregion

func start_game():
	hide_lobby.rpc()
	is_host = multiplayer.is_server()
	time = 0
	bc.stc_start_music.rpc(Time.get_unix_time_from_system())
	if spawn_dummy:
		# for testing.
		spawner.custom_spawn("res://ver_1/character/enemy/Dummy/dummy.tscn", Vector2(-800,-450))
		#spawner.custom_spawn("res://ver_1/character/enemy/MajorBug/major_bug.tscn", Vector2(651,335))
		#spawner.custom_spawn("res://ver_1/character/enemy/MinorBug/minor_bug.tscn", Vector2(651,235))
		#spawner.custom_spawn("res://ver_1/character/enemy/Shooter/shooter.tscn", Vector2(651,132))
		#spawner.custom_spawn("res://ver_1/character/enemy/Shooter/shooter.tscn", Vector2(651,136))
		#spawner.custom_spawn("res://ver_1/character/enemy/Shooter/shooter.tscn", Vector2(651,133))
		
	if infinite_health:
		for hero : BaseHero in players:
			hero.char_stats.maxhp = 1000000
			hero.current_health = 1000000
	if spawn_boss:
		# we set this because otherwise, players can level up and desync boss music
		dont_spawn_enemies = true 
		spawner.custom_spawn("res://ver_1/character/enemy/boss/B&B/bnb.tscn", Vector2(0,0))
		#spawner.custom_spawn("res://ver_1/character/enemy/boss/Biano/biano.tscn", Vector2(0,35))
		#spawner.custom_spawn("res://ver_1/character/enemy/boss/Beethoven/beethoven.tscn", Vector2(-10,25))
	if dont_spawn_enemies: 
		return
	spawner._start_timer()

@rpc("authority", "call_local")
func hide_lobby():
	get_node("WaitingLobby").turn_off_lobby()
	map.visible = true
	
	# put this here, so it can be synced by the client as well.
	is_started = true

func reset_game():
	current_gm_scene.queue_free()
	current_gm_scene = gm_scene.instantiate()
	add_sibling(current_gm_scene)

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
	if not quick_leveling:
		max_xp = sample(current_lvl)
	ui.update_max_xp(max_xp)

### Card Sequence 
#region Card Sequence

#DEPRECATED
func serialize(action : BaseAction) -> String:
	var rs : String = action.get_script().resource_path
	rs = rs.get_file().get_slice(".", 0)
	return rs

#DEPRECATED
func deserialize(string : String) -> BaseAction:
	# add a check for abilities as well...
	var action = load("res://ver_1/actions/items/" + string + ".gd").new() as BaseAction
	return action

#DEPRECATED
func script_name_to_item_scene(string) -> String:
	var filename : String = string.resource_path
	filename = filename.get_file().get_slice(".", 0)
	filename += ".tscn"
	return "res://ver_1/actions/items/" + filename

func start_level_up_sequence():
	players_ready = 0
	for player in players:
		# the items for each player could be different
		# lets set it to same for now
		var actions_index = choose_actions(player)
		client_level_up.rpc_id(player.id, actions_index)

# Algorithm for choosing actions for level up.
func choose_actions(_hero : BaseHero) -> Array[int]:
	var array : Array[int] = []
	
	# Select three actions randomly
	for x in 3:
		var _action_index : int
		var is_action_valid : int
		while true:
			_action_index = action_list.get_random_action()
			is_action_valid = action_list.is_action_valid(_action_index, _hero)
			
			if is_action_valid == 0:
				continue
			elif is_action_valid == 1:
				break
			else: 
				# This happens when uve maxed out everything 
				# for now if u've maxed out everything, return a max health card.
				_action_index = 8
				break
		array.append(_action_index)
	return array

# refactor -> pass an  integer instead of an action
func tell_server_client_is_ready(action_index):
	client_selection_ready.rpc_id(1, action_index)

# Process and give item
@rpc("authority", "call_local", "reliable")
func parse_action_card(id : int, action_index : int):
	var player : BaseHero = get_player(id)

	var action = action_list.get_new_class_script(action_index) as BaseAction

	if action is BaseItem:
		if !player.has_item(action_index):
			player.add_item(action_index)
		else:
			player.upgrade_item(action)
	
	if action is BaseAbility:
		var ability = player.get_action(action) as BaseAbility
		if ability == null: return
		
		ability._upgrade()
	
	if action is BaseStatCard:
		if player.has_stat(action_index):
			player.upgrade_stat(action_index)
		else:
			player.add_stat(action_index)
	
	action.queue_free()

### RPC Calls
@rpc("call_local", "reliable")
func client_level_up(items : Array):
	is_paused = true
	start_lvl_up_sequence.emit(items)

# run on the server only.
@rpc("call_local", "any_peer")
func client_selection_ready(action_index):
	players_ready += 1
	parse_action_card.rpc(multiplayer.get_remote_sender_id(), action_index)
	
	if players_ready == players.size():
		tell_client_end_card_sequence.rpc()

@rpc("call_local",  "unreliable_ordered")
func tell_client_end_card_sequence():
	is_paused = false
	
	# FIXME: Currently assume that its always an lvl up for card. 
	change_max_xp()
	current_lvl += 1
	end_lvl_up_sequence.emit()

#endregion

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

func show_character_select_screen(_arg = 1):
	# this _arg is not used.
	ui.show_character_select()

# turns off main menu ui and shows gameplay ui
func change_ui():
	ui.show_ui()
	get_parent().display_all_ui(false)

# Get max xp from lvl.
func sample(_lvl : int) -> int:
	return max_xp + (15 * _lvl)

# Death & Strawberry: Players connect to this function player.player_die signal rpc call this by GM.
func check_alive_players() -> void:
	if !multiplayer.is_server(): return
	if players.size() == 0: return #dont check if theres no-one
	if is_started == false: return # dont check if we havent started.
	
	for x in players:
		if !x.IS_DEAD:
			return
	# End game, players all dead
	tell_everyone_end_game.rpc()

# check if the client running this controls this the character on their screen.
func is_local_player(id : int):
	if id == local_player.id:
		return true
	else:
		return false

# Turns on cinematic bars and tween camera.
func boss_cinematic_camera_move(id ,_gpos : Vector2, time : float, delay : float = 0):
	tween_camera_to_pos(id, _gpos, time, delay)
	ui.turn_on_cinematic_bars(id)

# Shakes all players camera by given strength and fade (how long it returns to normal)
# Time to completion= strength/fade
func screen_shake(strength : float, fade : float):
	local_player.camera.start_shake(strength, fade)

# tweens the player's camera to a given position, pauses for x seconds, then instantly goes back to the original position
func tween_camera_to_pos(id, _gpos : Vector2, time : float, delay : float = 0):
	var player_cam = local_player.camera
	var tween = player_cam.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(local_player.camera, "global_position", _gpos, time)
	tween.tween_property(player_cam, "global_position", player_cam.global_position, 0).set_delay(delay)
	tween.finished.connect(on_tween_finish.bind(id))

func on_tween_finish(id):
	local_player.camera.position = Vector2.ZERO
	ui.turn_off_cinematic_bars(id)

#region BnB Phase 2 centralised code
# These will be moved if there is a centralized script for the two (which I dont think we should separate or sth) 
var dance_sequence_started : bool
var dance_second_solo_started : bool
var dance_duo_started : bool
var dance_positions : Array[Vector2] = [Vector2(200,0), Vector2(-200,0)]
var duo_dance_positions : Array[Vector2] = [Vector2(50,0), Vector2(-50, 0)]
var dance_scene : PackedScene = load("res://ver_1/character/enemy/boss/dance_walls.tscn")
var duo_dance_scene : PackedScene = load("res://ver_1/character/enemy/boss/duo_dance_wall.tscn")
var live_duo_scene

# this will also be called on the clientside
# this is for the first solo, so the server is blacked while the other player tells you where.
func start_dance_sequence():
	if dance_sequence_started: return
	dance_sequence_started = true
	local_player.camera.zoom = Vector2.ONE
	
	live_duo_scene = duo_dance_scene.instantiate()
	live_duo_scene.global_position = Vector2.ZERO
	map.add_child(live_duo_scene)
	live_duo_scene.process_mode = Node.PROCESS_MODE_DISABLED # disable static collisions
	live_duo_scene.visible = false
	
	#create a dance map for each player
	for x in players.size(): # players .size() is multiplayer safe
		var copy = dance_scene.instantiate()
		copy.global_position = dance_positions[x]
		copy.name = copy.name +  str(players[x].get_multiplayer_authority())
		map.add_child(copy)
		
	
	if multiplayer.get_unique_id() == 1:
		map.get_node("DanceWalls" + str(1)).get_node("BlackSprite").visible = true
		pass
	
	# only execute teleport if you are on the server.
	if multiplayer.is_server():
		for x in players.size():
			# check if we are being knocked while teleporting.
			players[x].status_holder.tell_clients_to_remove_status.rpc("Knockback")
			players[x].teleport.rpc(dance_positions[x])

func start_second_solo():
	if dance_second_solo_started: return
	dance_second_solo_started = true
	
	# if for some reason theres only one person, dont do anything
	if players.size() == 1: return 
	
	# turn on black cover for player 2
	if multiplayer.get_unique_id() == players[1].get_multiplayer_authority():
		map.get_node("DanceWalls" + str(multiplayer.get_unique_id())).get_node("BlackSprite").visible = true
	
	# turn off black cover for player 1 (server)
	if multiplayer.is_server():
		map.get_node("DanceWalls" + str(1)).get_node("BlackSprite").visible = false
	
	
func start_dance_duo():
	if dance_duo_started: return
	GameManager.Instance.bc
	
	# remove all black covers and cut the middle collider from each scene
	for x in players.size():
		var personal_dance_wall = map.get_node("DanceWalls" + str(players[x].get_multiplayer_authority()))
		personal_dance_wall.get_node("BlackSprite").visible = false
		personal_dance_wall.queue_free()
	
	live_duo_scene.process_mode = Node.PROCESS_MODE_INHERIT
	live_duo_scene.visible = true
	
	# teleport players just incase the duo borders are spawned outside the player's location.
	if multiplayer.is_server():
		for x in players.size():
			players[x].teleport.rpc(duo_dance_positions[x])

func end_dance_sequence():
	local_player.camera.zoom = Vector2(1.5, 1.5)
	dance_sequence_started = false
	dance_second_solo_started = false
	dance_duo_started = false
	live_duo_scene.queue_free()

func boss_duo_defeated():
	map.get_node("ArenaBuildings").visible = false
	if map.has_node("ArenaWalls"):
		map.get_node("ArenaWalls").queue_free()
#endregion
