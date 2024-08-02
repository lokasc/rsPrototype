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

func _process(delta):
	if !is_game_started:
		return
	
	if is_countdown_started:
		# start countdown.
		timer.start()
		cd_number_visual.text = str(timer.time_left)
	pass

### GAMEPLAY ###
# A visual label shrinks & fades to the center labelled 3 then 2 then 1. 
# Afterwords, a transparent ring surrounds the circle appears 
# and a white ring outside 
# Player will need to press m1 when the 


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

