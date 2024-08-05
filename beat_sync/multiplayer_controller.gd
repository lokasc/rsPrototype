extends Node

const PORT = 28960
const MAX_CLIENTS = 2

@export var net_ui : Control
@export var game_ui : Control
@export var timer : Timer 
@export var cd_number_visual : Label

var is_game_started : bool = false

var is_countdown_started : bool = false # set this to true to start a countdown.


var ip_address = "127.0.0.1"
var peer
var player_name : String = ""


# GAMEPLAY
var BPM : float = 100

enum GAME_STATE {STATE_IDLE, STATE_RUNNING, STATE_RESULTS}
var current_state : GAME_STATE = GAME_STATE.STATE_IDLE

var seconds_per_four_beats : float = BPM/60.0 * 4
# this is a hard limit, if you dont press within these extra beats,
# automatically count as failure
var extra_seconds : float = seconds_per_four_beats/4 * 5 


# Statistics
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
	
	current_state = GAME_STATE.STATE_IDLE

func _process(delta):
	if !is_game_started:
		return
	
	game_loop()
	pass

### GAMEPLAY ###
# Afterwords, a transparent ring surrounds the circle appears 
# and a white ring outside 
# Player will need to press m1 when the rings overlap

	# 1. Decide BPM.
	# 2. Start counting down.
	# 3. Check for hits.
	# 4. get results, wait.

# This function corresponds to the main gameplay
func game_loop():
	print(current_state)
	match current_state:
		GAME_STATE.STATE_IDLE:
			await get_tree().create_timer(1).timeout
			
			# for 4 crotchets, how many seconds? + extra.
			var total_cd_time = seconds_per_four_beats + extra_seconds
			timer.start(total_cd_time)
			current_state = GAME_STATE.STATE_RUNNING
			
		GAME_STATE.STATE_RUNNING:
			# Check for Input & collect results.
			if Input.is_action_just_pressed("attack"):
				pressed_time = timer.time_left
			
				# negative implies early, positive implies late.
				accuracy = seconds_per_four_beats - pressed_time
				print("Time left: " + str(timer.time_left) + "\n Accuracy: " + str(accuracy))
			
				# stop timer when hit 
				timer.stop()
				current_state = GAME_STATE.STATE_RESULTS
		
		GAME_STATE.STATE_RESULTS:
			# show results here, for x seconds then go next.
			pass


func _on_cd_timer_timeout():
	accuracy = 99999
	current_state = GAME_STATE.STATE_RESULTS

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



