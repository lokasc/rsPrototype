extends Node

const PORT = 28960
const MAX_CLIENTS = 2

signal client_ready_signal
signal client_results_ready_signal

@export var net_ui : Control
@export var game_ui : Control
@export var timer : Timer

@export var sound_timer : Timer
@export var transparent_ring : Sprite2D
@export var opaque_ring : Sprite2D
@export var hihat_sound : AudioStreamPlayer

@export_subgroup("Stats")
@export var stats_container : VBoxContainer
@export var players_delay_label : RichTextLabel

@export_category("Game")
@export var result_screen_time : float
@export_range(1,15) var num_countdowns : int

@export_subgroup("BPM")
## If toggled on, the BPM will be set as the max BPM
@export var BPM_CONSTANT : bool = false
@export var min_BPM : int = 100
@export var max_BPM : int = 30

### NETWORKING
var ip_address = "127.0.0.1"
var peer
var player_name : String = ""
var is_bpm_sent : bool = false
var is_delay_sent : bool = false

var _ping_start_time : float
var final_ping_time : float
var delta_pings : float = 1
var _current_ping_timer : float = 0

# SYNC_VAR
var sync_client_results_ready : bool
var sync_client_ready : bool
var same_state : bool

### GAMEPLAY
var is_game_started : bool = false
enum GAME_STATE {STATE_IDLE, STATE_WAITING, STATE_RUNNING, STATE_RESULTS}
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
# negative implies early, positive implies late.
var accuracy
var friend_accuracy = null
var friend_state = null

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
	
	#SYNC SIGNALS
	client_ready_signal.connect(on_client_ready_signal)
	client_results_ready_signal.connect(on_client_results_ready_signal)
	
	#SYNCVARS
	sync_client_results_ready = false
	sync_client_ready = false
	same_state = false
	
	
	BPM = null
	min_BPM = 3600/min_BPM
	max_BPM = 3600/max_BPM

func _process(delta):
	if !is_game_started:
		return
	
	
	# SEND BPM DATA to other player.
	# WAIT FOR CONFIRMATION BEFORE PROCEEDING
	# CLIENT SEND PACKET TO SERVER FOR CONFIRMATION
	# SERVER SEND TO CLIENTS TO START THE COUNTDOWN 
	
	await game_loop(delta)

# call rpc here, ignores the await in game loop.
func _physics_process(delta):
	state_indicator(current_state)
	
	_current_ping_timer += delta
	
	if _current_ping_timer >= delta_pings:
		_current_ping_timer = 0
		ping.rpc_id(1, Time.get_unix_time_from_system())
	pass

### GAMEPLAY ###
# Players need to press m0 when the opaque ring overlaps
# the transparent ring

# This function corresponds to the main gameplay
func game_loop(_delta):
	#print(current_state)
	match current_state:
		GAME_STATE.STATE_IDLE:
			
			if multiplayer.is_server():
				if same_state == false:
					ask_client_is_ready.rpc(current_state)
					print("im sending RPC to check")
					return
				else:
					# check if both clients are at the same state.
					if is_bpm_sent == false:
						if BPM_CONSTANT:
							send_bpm_rpc.rpc(max_BPM)
						else:
							BPM = randi_range(max_BPM, min_BPM)
							send_bpm_rpc.rpc(BPM)
						is_bpm_sent = true

			## waits for all clients.
			# BUG: if server pressed too fast,
			# client is not ready to recieve signal when server sends it.
			#	await client_ready_signal
			if !sync_client_ready:
				return 
		
			
			seconds_per_four_beats = BPM/60.0 * 4
			extra_seconds = seconds_per_four_beats/4 * 2
			
			# for 4 crotchets, how many seconds? + extra.
			total_cd_time = seconds_per_four_beats + extra_seconds
			timer.start(total_cd_time)
			
			## play a sound effect on first beat.
			sound_count = 0
			opaque_ring_scale = opaque_ring_scale
			$"../Countdowns/Ring".modulate = Color(0,0,0)
			sound_timer.start(seconds_per_four_beats/8)
			
			switch_state(current_state, GAME_STATE.STATE_RUNNING)
			return
		GAME_STATE.STATE_RUNNING:
			# Shrink visual image, via linear interpolation. 
			opaque_ring.scale = opaque_ring_scale + ((transparent_ring_scale - opaque_ring_scale)/(seconds_per_four_beats-0)) * (total_cd_time - timer.time_left-0)
			if opaque_ring.scale.x < 0:
				opaque_ring.scale = Vector2.ZERO
			
			if current_state != GAME_STATE.STATE_RUNNING:
				return
			
			# Check for Input & collect results.
			if Input.is_action_just_pressed("attack"):
				$"../Countdowns/Ring".modulate = Color(0,1,0)
				
				pressed_time = timer.time_left
				timer.stop()
				sound_timer.stop()
				$"../Countdowns/CorrectBuzzerNoise".play(0.15)
				
				accuracy =  total_cd_time - pressed_time - seconds_per_four_beats
				#print("Time left: " + str(pressed_time) + "\n Accuracy: " + str(accuracy))
				
				if !multiplayer.is_server():
					send_press_time.rpc_id(1, accuracy, Time.get_unix_time_from_system())
				
				set_accuracy()
				$"../Countdowns/StatsContainer/ButtonPressDelay".text = "Time between players: WAITING"
				# stop timer when hit 
				switch_state(current_state, GAME_STATE.STATE_RESULTS)
		GAME_STATE.STATE_RESULTS:
			if current_state != GAME_STATE.STATE_RESULTS:
				return # sanity check, it can happen.
			
			# Synchronise step, wait until I get result
			if friend_accuracy == null:
				return
			
			# recieved result, go next.
			if multiplayer.is_server() && is_delay_sent == false:
				var player_diff = abs(friend_accuracy - accuracy)
				pong_button_press_delay.rpc(player_diff)
				is_delay_sent = true
			
			# client has recieved delay results
			if !multiplayer.is_server() && is_delay_sent == false:
				client_results_ready.rpc_id(1)
				is_delay_sent = true
			
			
			#await client_results_ready_signal
			if !sync_client_results_ready:
				return
			
			await get_tree().create_timer(result_screen_time).timeout
			
			# check to end game.
			# for some reason, it is possible to enter here 
			# without being in state_result
			if current_state == GAME_STATE.STATE_RESULTS:
				current_countdowns += 1
				
				# reset variables
				friend_accuracy = null
				accuracy = null
				is_bpm_sent = false
				is_delay_sent = false
				sync_client_results_ready = false
				sync_client_ready = false
				same_state = false
				
				reset_stat_strings()
				if current_countdowns >= num_countdowns:
					is_game_started = false
					return
				switch_state(current_state, GAME_STATE.STATE_IDLE)
			return

func _on_cd_timer_timeout():
	if current_state != GAME_STATE.STATE_RUNNING:
		return
	accuracy = 123456789
	if !multiplayer.is_server():
		send_press_time.rpc_id(1, accuracy, Time.get_unix_time_from_system())
	set_accuracy()
	$"../Countdowns/StatsContainer/ButtonPressDelay".text = "Time between players: WAITING"
	switch_state(current_state, GAME_STATE.STATE_RESULTS)

func _on_sound_timer_timeout():
	hihat_sound.stop()
	sound_count += 1
	hihat_sound.play()
	
	# stop countdown.
	if sound_count >= 7:
		sound_timer.stop()

func reset_stat_strings():
	$"../Countdowns/StatsContainer/Accuracy".text = "Accuracy"
	$"../Countdowns/StatsContainer/Ping".text = "Client Delay"
	$"../Countdowns/StatsContainer/ButtonPressDelay".text = "Time between players:"
func set_accuracy():
	var string
	
	# TODO: maybe turn green or something within a range
	if sign(accuracy) == -1:
		string = "Early by " + str(abs(accuracy)) + "s"
	elif sign(accuracy) == 1:
		string = "Late by " + str(abs(accuracy)) + "s"
	else:
		string = "Perfect!"
	
	stats_container.get_child(0).text = "Accuracy: " + string

### DEBUG ###
func switch_state(old, new):
	if old == new: return
	
	current_state = new
	#if multiplayer.is_server():
		#return
	#print("old:" + str(old) + " to " + "new:" + str(new))

func on_client_ready_signal():
	sync_client_ready = true
	pass
	#if multiplayer.is_server():
		#return
	#print("signal emitted")

func on_client_results_ready_signal():
	sync_client_results_ready = true

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
	#game_ui.get_node("StartGameButton").visible = true # SOLOTEST

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
	
	if multiplayer.is_server():
		game_ui.get_node("StartGameButton").visible = true
	pass

func _on_player_disconnect(id):
	friend_details["name"] = null
	friend_details["id"] = null
	$"../UI/InGameUI/VBoxContainer/FriendID".text = ""
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
		$"../UI/InGameUI/VBoxContainer/FriendID".text = "[center]" + friend_details["name"] + " Connected"
	else:
		$"../UI/InGameUI/VBoxContainer/FriendID".text = "[center]" + "Connected to " + friend_details["name"]

@rpc("authority", "reliable", "call_local")
func start_game():
	is_game_started = true

func _on_start_game_button_button_down():
	is_game_started = true
	
	start_game.rpc()
	game_ui.get_node("StartGameButton").visible = false
	pass


# this sends and changes bpm on all machines
@rpc("call_local", "reliable", "authority")
func send_bpm_rpc(bpm):
	change_bpm(bpm)
	
	# Let server know client has recieved and ready.
	# we need to continuously ask until it is ready.
	if !multiplayer.is_server() && current_state == GAME_STATE.STATE_IDLE:
		#print("IM CALLING FROM CLIENT")
		client_ready.rpc_id(1, multiplayer.get_unique_id())
	return

@rpc("reliable", "any_peer")
func client_ready(id):
	if !multiplayer.is_server():
		return
	
	# server understands client, tells all clients to start.
	emit_all_client_ready_signal.rpc()
	pass

# tells all clients to continue.
@rpc("any_peer", "reliable", "call_local")
func emit_all_client_ready_signal():
	client_ready_signal.emit()

@rpc("reliable", "any_peer")
func client_results_ready():
	if !multiplayer.is_server():
		return
	emit_all_results_ready_signal.rpc()

# tells all clients to continue.
@rpc("any_peer", "reliable", "call_local")
func emit_all_results_ready_signal():
	client_results_ready_signal.emit()

func change_bpm(new_bpm):
	BPM = new_bpm
	#print("I've changed BPM!")


# only sent to server by client
@rpc("any_peer")
func send_press_time(pressed_time : float, unix_time : float):
	friend_accuracy = pressed_time
	#client_ready_signal.emit()

@rpc("any_peer", "call_local")
func pong_button_press_delay(delay : float):
	players_delay_label.text = "Time between players: " + str(delay) + "s"
	friend_accuracy = delay


# pinging starts from the player, then to the server.
@rpc("any_peer", "call_local")
func ping(start_time : float):
	var sender_id = multiplayer.get_remote_sender_id()
	pong.rpc_id(sender_id, start_time)
	pass

@rpc("any_peer", "call_local")
func pong(start_time :float):
	final_ping_time = Time.get_unix_time_from_system() - start_time
	$"../UI/InGameUI/VBoxContainer/Ping".text = "PING TO SERVER: " + str(final_ping_time) + "s"

func state_indicator(state):
	var string
	match state:
		GAME_STATE.STATE_IDLE: 
			string = "IDLE"
		GAME_STATE.STATE_RUNNING:
			string = "RUNNING"
		GAME_STATE.STATE_RESULTS:
			string = "RESULTS"
	
	if is_game_started == false:
		string = "GAME_END"
	$"../UI/InGameUI/StateIndicator".text = string

@rpc("unreliable")
func ask_client_is_ready(state):
	if multiplayer.is_server():
		return
	
	return_state_check.rpc_id(1, is_same_state(state))
	pass

# call to server only
@rpc("unreliable", "call_local", "any_peer")
func return_state_check(x : bool):
	same_state = x

#executed on the client
func is_same_state(state) -> bool:
	if state == current_state:
		return true
	else:
		return false
