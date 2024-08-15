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

@export var connected_players = []
@export var player_scene : PackedScene

#Move this code to gamemanager
@export var is_game_started : bool = false

func _ready():
	multiplayer.server_relay = false
	
	peer = ENetMultiplayerPeer.new()
	_connect_net_signals()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if !multiplayer.is_server(): return
	if !is_game_started && get_player_count() >= 1:
		is_game_started = true
		var enemy_spawner = $EnemySpawner as EnemySpawner
		enemy_spawner._start_timer()
		print("Game_started!!")
	pass

func get_player_count():
	return connected_players.size()

func on_host_pressed():
	peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	# Set UI
	$AuthLabel.text = "Server"
	$IdLabel.text = str(multiplayer.get_unique_id())
	connected_players.append(multiplayer.get_unique_id())
	
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

func _connect_net_signals():
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
	#if connected_players.has(id):
		#return
	#
	connected_players.append(id)
	
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	player.call_deferred("add_to_group", "players")

func _on_peer_disconnect(id):
	pass

func _on_connection_failed():
	pass

# only on clientside
func _on_client_connect():
	pass

func _on_client_disconnect():
	pass

