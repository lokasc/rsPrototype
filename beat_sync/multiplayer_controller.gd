extends Node

const PORT = 28960
const MAX_CLIENTS = 2

@export var net_ui : Control
@export var game_ui : Control


var ip_address = "" # determined via user input.
var peer


func _ready():
	net_ui.visible = true
	game_ui.visible = false

func _process(delta):
	pass

# Creates a client given ip_address
func innit_client():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = peer

# Creates a server
func innit_host():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer

func join_server():
	# joins server.
	pass


func _on_host_button_button_down():
	print("HOST PRESSED!")
	innit_host()
	
	# set initial ui
	net_ui.visible = false
	game_ui.visible = true
	(game_ui.get_child(0) as Label).text = "ID: " + str(multiplayer.get_unique_id()) + " (Server)"
	pass 


func _on_join_button_button_down():
	print("CLIENT PRESSED!")
	
	var ip_node = get_node("/root/BeatMain/UI/NetUI/HBoxContainer/IP") as TextEdit
	ip_address = ip_node.text
	
	# check if null
	if (ip_address == "" or ip_address == null):
		OS.alert("Need an IP to connect to")
		return

	# check for timeout on connection.

	innit_client()
	net_ui.visible = false
	game_ui.visible = true
	
	(game_ui.get_child(0) as Label).text = "ID: " + str(multiplayer.get_unique_id()) + " (Client)"
