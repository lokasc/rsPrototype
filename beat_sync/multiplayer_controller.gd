extends Node

const PORT = 28960
const MAX_CLIENTS = 2

@export var net_ui : Control
@export var game_ui : Control


var ip_address = "127.0.0.1"
var peer

func _ready():
	print(IP.get_local_addresses()[3])
	# Initialise signals.
	multiplayer.peer_connected.connect(_on_player_connect)
	multiplayer.peer_disconnected.connect(_on_player_disconnect)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	net_ui.visible = true
	game_ui.visible = false

func _process(delta):
	if peer != null:
		print(peer.get_connection_status())
	pass

# Creates a client given ip_address
func innit_client():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, PORT)
	
	if error != OK:
		OS.alert("Shit input?")
		peer = null
		error = null
		return
	
	multiplayer.multiplayer_peer = peer
	
	net_ui.visible = false
	game_ui.visible = true
	(game_ui.get_child(0) as Label).text = "Connecting to: " + ip_address

# Creates a server
func innit_host():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	print("Server started on port " + str(PORT) + " with a maximum of " + str(MAX_CLIENTS) + " clients")

func _on_host_button_button_down():
	innit_host()
	
	# set initial ui
	net_ui.visible = false
	game_ui.visible = true
	(game_ui.get_child(0) as Label).text = "ID: " + str(multiplayer.get_unique_id()) + " (Server)"
	pass 


func _on_join_button_button_down():
	print("CLIENT PRESSED!")
	
	var input_ip = (get_node("/root/BeatMain/UI/NetUI/HBoxContainer/IP") as TextEdit).text
	if input_ip != "":
		ip_address = input_ip
	
	# check if null
	if (ip_address == "" or ip_address == null):
		OS.alert("Need an IP to connect to")
		return
		
	innit_client()

# TOOD: Want to set up showing whos on connected.
func _on_player_connect(id):
	print(id)
	pass

func _on_player_disconnect(id):
	pass

func _on_connection_failed():
	pass

func _on_connected_to_server():
	(game_ui.get_child(0) as Label).text = "ID: " + str(multiplayer.get_unique_id()) + " (Client)"
	pass
