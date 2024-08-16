class_name NetManager
extends Node

### Network Manager
# host_game()
# client_join()
# DO NOT ASSUME ID 1 IS THE OTHER PLAYER
# CURRENTLY WRITING FOR SPEED NOT FOR ARCHITECTURE
# CODE WILL CHANGE TO DEDICATED SEREVER ARCHITECTURE RATHER THAN SERVERCLIENT

const DEFAULT_ADDRESS = "127.0.0.1"
const DEFAULT_PORT = 28960
const MAX_CLIENTS = 2
var peer : ENetMultiplayerPeer

@export var player_scene : PackedScene
@onready var player_container : Node = $Players

func _enter_tree() -> void:
	GameManager.Instance.net = self
	pass

func _ready():
	multiplayer.server_relay = false
	peer = ENetMultiplayerPeer.new()
	_connect_signals()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !multiplayer.is_server(): return
	if !GameManager.Instance.is_game_started() && get_player_count() >= 1:
		GameManager.Instance.start_game()

func get_player_count():
	return GameManager.Instance.players.size()

func on_host_pressed():
	peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	# Set UI
	$AuthLabel.text = "Server"
	$IdLabel.text = str(multiplayer.get_unique_id())
	
	# This line adds players.
	multiplayer.peer_connected.connect(add_player)
	add_player()

func on_client_pressed():
	peer.create_client(DEFAULT_ADDRESS, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer
	
	# Set UI
	$AuthLabel.text = "Client"
	$IdLabel.text = str(multiplayer.get_unique_id())

# call this function to start a game.
func on_start_pressed():
	pass

func _connect_signals():
	# Player container
	player_container.child_entered_tree.connect(_add_to_list)
	
	# Others
	$NetUI.request_host.connect(on_host_pressed)
	$NetUI.request_client.connect(on_client_pressed)
	
	# Godot signals
	multiplayer.peer_connected.connect(_on_peer_connect)
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_client_connect)
	multiplayer.server_disconnected.connect(_on_client_disconnect)

# id is the person u've connected to
func _on_peer_connect(id):
	if multiplayer.is_server():
		$FriendLabel.text = str(id) + " connected"
	else:
		$FriendLabel.text = "Connected to: " + str(id) 

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	player_container.call_deferred("add_child", player, true)

func _add_to_list(node : Node):
	var new_player = node as BaseHero
	if new_player == null:
		printerr("Trying to add a non-hero to player list") 
		return
	
	GameManager.Instance.add_player_to_list(new_player)

func _on_peer_disconnect(id):
	pass

func _on_connection_failed():
	pass

# only on clientside
func _on_client_connect():
	pass

func _on_client_disconnect():
	pass