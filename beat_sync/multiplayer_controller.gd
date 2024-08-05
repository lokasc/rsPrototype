extends Node

const PORT = 28960
const MAX_CLIENTS = 2



@export var net_ui : Control
@export var game_ui : Control
@export var timer : Timer

@export var sound_timer : Timer
@export var transparent_ring : Sprite2D
@export var opaque_ring : Sprite2D
@export var hihat_sound : AudioStreamPlayer

@export_category("Game")
@export var result_screen_time : float
@export_range(1,15) var num_countdowns : int

@export_subgroup("BPM")
@export var min_BPM : int = 100
@export var max_BPM : int = 30

### NETWORKING
var ip_address = "127.0.0.1"
var peer
var player_name : String = ""

### GAMEPLAY
var is_game_started : bool = false
enum GAME_STATE {STATE_IDLE, STATE_RUNNING, STATE_RESULTS}
var current_state : GAME_STATE = GAME_STATE.STATE_IDLE
var current_countdowns : int

var BPM
var seconds_per_four_beats : float
# this is a hard limit, if you dont press within these extra beats,
# automatically count as failure
var extra_seconds : float
var total_cd_time : float

var opaque_ring_scale
var transparent_ring_scale

var sound_count

### Statistics
var pressed_time

# difference between the last crotchet and pressed time.
var accuracy

var friend_details = {
	"name" : null,
	"id" : null,
}

func _ready():
	# Initialise signals.
	multiplayer.peer_connected.connect(_on_player_connect)
	multiplayer.peer_disconnected.connect(_on_player_disconnect)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	net_ui.visible = true
	game_ui.visible = false
	game_ui.get_node("StartGameButton").visible = false
	
	### GAMEPLAY
	opaque_ring_scale = opaque_ring.scale
	transparent_ring_scale = transparent_ring.scale
	current_state = GAME_STATE.STATE_IDLE
	current_countdowns = 0

func _process(delta):
	if !is_game_started:
		return
	
	game_loop()
	pass

### GAMEPLAY ###
# Players need to press m0 when the opaque ring overlaps
# the transparent ring

	# 1. Decide BPM.
	# 2. Start counting down.
	# 3. Check for hits.
	# 4. get results, wait.

# This function corresponds to the main gameplay
func game_loop():
	match current_state:
		GAME_STATE.STATE_IDLE:
			await get_tree().create_timer(1).timeout
			
			# Calculate a random BPM
			BPM = randi_range(max_BPM, min_BPM)
			seconds_per_four_beats = BPM/60.0 * 4
			extra_seconds = seconds_per_four_beats/4 * 2
			
			# for 4 crotchets, how many seconds? + extra.
			total_cd_time = seconds_per_four_beats + extra_seconds
			timer.start(total_cd_time)
			
			## play a sound effect on first beat.
			sound_count = 0
			sound_timer.start(seconds_per_four_beats/4)
			
			current_state = GAME_STATE.STATE_RUNNING
			
		GAME_STATE.STATE_RUNNING:
			# Shrink visual image, via linear interpolation. 
			# TODO: make it extend beyond.
			# FIXME: Scaling buggy at the beginning.
			opaque_ring.scale = opaque_ring_scale + ((transparent_ring_scale - opaque_ring_scale)/(seconds_per_four_beats-0)) * (min(total_cd_time - timer.time_left,seconds_per_four_beats)-0)
			# Check for Input & collect results.
			if Input.is_action_just_pressed("attack"):
				pressed_time = timer.time_left
				timer.stop()
				sound_timer.stop()
			
				# negative implies early, positive implies late.
				accuracy =  total_cd_time - pressed_time - seconds_per_four_beats
				print("Time left: " + str(pressed_time) + "\n Accuracy: " + str(accuracy))
				
				# stop timer when hit 
				current_state = GAME_STATE.STATE_RESULTS
		GAME_STATE.STATE_RESULTS:
			# show results here, for x seconds then go next.
			await get_tree().create_timer(result_screen_time).timeout
			# check to leave.
			
			# for some reason, it is possible to enter here 
			# without being in state_result
			if current_state == GAME_STATE.STATE_RESULTS:
				current_countdowns += 1
				if current_countdowns >= num_countdowns:
					is_game_started = false
					return
			current_state = GAME_STATE.STATE_IDLE
			return

func _on_cd_timer_timeout():
	if current_state != GAME_STATE.STATE_RUNNING:
		return
	accuracy = 99999
	current_state = GAME_STATE.STATE_RESULTS

func _on_sound_timer_timeout():
	hihat_sound.stop()
	sound_count += 1
	hihat_sound.play()
	
	if sound_count >= 3:
		# play different sound
		sound_timer.stop()


### NETWORKING ###

# Creates a client given ip_address
func innit_client():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, PORT)
	
	if error != OK:
		OS.alert("Check your input")
		peer = null
		error = null
		return
	
	multiplayer.multiplayer_peer = peer
	
	net_ui.visible = false
	game_ui.visible = true
	player_name = net_ui.get_child(1).text
	
	(game_ui.get_child(0) as Label).text = "Connecting to: " + ip_address

# Creates a server
func innit_host():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	
	# TODO: Check for hosting issues

	multiplayer.multiplayer_peer = peer
	print("Server started on port " + str(PORT) + " with a maximum of " + str(MAX_CLIENTS) + " clients")

func _on_host_button_button_down():
	innit_host()
	
	# set initial ui
	net_ui.visible = false
	game_ui.visible = true
	player_name = net_ui.get_child(1).text
	(game_ui.get_child(0) as Label).text = "ID: " + str(multiplayer.get_unique_id()) + " (Server)"
	game_ui.get_node("StartGameButton").visible = true

	pass 


func _on_join_button_button_down():
	var input_ip = (get_node("/root/BeatMain/UI/NetUI/HBoxContainer/IP") as TextEdit).text
	if input_ip != "":
		ip_address = input_ip
	
	# check if null
	if (ip_address == "" or ip_address == null):
		OS.alert("Need an IP to connect to")
		return
		
	innit_client()

# Whenever something else connects to you.
func _on_player_connect(id):
	# call rpcs here and names....
	friend_details["id"] = id
	transfer_name.rpc(player_name)
	
	#if multiplayer.is_server():
		#game_ui.get_node("StartGameButton").visible = true
	pass

func _on_player_disconnect(id):
	friend_details["name"] = null
	friend_details["id"] = null
	game_ui.get_child(1).text = ""
	game_ui.get_node("StartGameButton").visible = false
	pass

func _on_connection_failed():
	pass

func _on_connected_to_server():
	(game_ui.get_child(0) as Label).text = "ID: " + str(multiplayer.get_unique_id()) + " (Client)"

# call remote sends to others only. not to self.
@rpc("any_peer", "unreliable", "call_remote")
func transfer_name(name):
	friend_details["name"] = name
	
	if multiplayer.is_server():
		game_ui.get_child(1).text = "[center]" + friend_details["name"] + " Connected"
	else:
		game_ui.get_child(1).text = "[center]" + "Connected to " + friend_details["name"]
	pass

@rpc("authority", "reliable", "call_local")
func start_game():
	is_game_started = true


func _on_start_game_button_button_down():
	is_game_started = true
	
	#start_game.rpc()
	game_ui.get_node("StartGameButton").visible = false
	pass





