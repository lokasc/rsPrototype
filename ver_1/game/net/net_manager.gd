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
var MAX_CLIENTS = 2

# Steam
var app_id : int = 480
var host_lobby_id : int = 0

@export var use_steam : bool
var steam_peer : SteamMultiplayerPeer
var enet_peer : ENetMultiplayerPeer

@export var auth_label : Label
@export var id_label : Label
@export var friend_label : Label
@export var net_ui : Control
@export var player_scene : PackedScene

var label_duration : int = 10

@onready var spawnable_path : Node2D = $Spawnables
@onready var player_container : Node = $Players
@onready var label_timer : Timer = $LabelTimer

@export var trebbie_scene : PackedScene
@export var bass_scene : PackedScene

# Initialize steam
func _init() -> void:
	OS.set_environment("SteamAppId", str(app_id))
	OS.set_environment("SteamGameId", str(app_id))

func _enter_tree() -> void:
	GameManager.Instance.net = self

func _ready():
	_connect_signals()
	multiplayer.server_relay = false

# Called by Main
func peer_type_switch(main_use_steam):
	#print(main_use_steam)
	if main_use_steam:
		use_steam = true
		init_steam()
		steam_peer = SteamMultiplayerPeer.new()
		_connect_steam_signals()
		enet_peer = null
		#print("Using Steam!")
	else:
		use_steam = false
		enet_peer = ENetMultiplayerPeer.new()
		steam_peer = null
		#print("Using ENET!")

# wrapper for steam & enet
func host_pressed():
	if use_steam:
		steam_host()
	else:
		enet_host()

func sp_pressed():
	MAX_CLIENTS = 1
	if use_steam:
		steam_host()
	else:
		enet_host()

func client_pressed(ip):
	if use_steam:
		steam_client()
	else:
		enet_client(ip)

func steam_host():
	steam_peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC, MAX_CLIENTS)
	auth_label.text = "Creating Lobby"

func enet_host():
	enet_peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = enet_peer

	# Set UI
	auth_label.text = "Server"
	id_label.text = str(multiplayer.get_unique_id())

	GameManager.Instance.show_character_select_screen()
	GameManager.Instance.change_ui()

func steam_client():
	# Set UI & show lobbies
	auth_label.text = "Client"
	list_lobbies()
	pass

func enet_client(ip):
	if ip == "":
		enet_peer.create_client(DEFAULT_ADDRESS, DEFAULT_PORT)
	else:
		enet_peer.create_client(ip, DEFAULT_PORT)
	multiplayer.multiplayer_peer = enet_peer

	# Set UI
	auth_label.text = "Client"
	id_label.text = str(multiplayer.get_unique_id())
	GameManager.Instance.change_ui()
	GameManager.Instance.show_character_select_screen()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if use_steam: Steam.run_callbacks()

#region steam
func init_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s" % initialize_response)
	
	if initialize_response['status'] > 0:
		print("Failed to initialize Steam, shutting down: %s" % initialize_response)
		get_tree().quit()
	
	# check if player owns the game.
	if !Steam.isSubscribed(): 
		printerr("Steam is not on, or we dont have this game")
		get_tree().quit()
	Steam.setGlobalConfigValueInt32(Steam.NETWORKING_CONFIG_SEND_BUFFER_SIZE, 1048576)
	Steam.setGlobalConfigValueInt32(Steam.NETWORKING_CONFIG_RECV_BUFFER_SIZE, 1048576)
	
	

func _on_lobby_created(connect: int, lobby_id):
	if connect != 1: return
	multiplayer.multiplayer_peer = steam_peer
	id_label.text = str(multiplayer.get_unique_id())
	
	auth_label.text = "Host"
	
	GameManager.Instance.show_character_select_screen()
	GameManager.Instance.change_ui()
	host_lobby_id = lobby_id
	print("Created" + str(host_lobby_id))
	
	# Set this lobby as joinable, just in case, though this should be done by default
	Steam.setLobbyJoinable(lobby_id, true)

	# Set some lobby data
	#var player_name : String = Steam.getPersonaName()
	Steam.setLobbyData(lobby_id, "name", "RH")
	Steam.setLobbyData(lobby_id, "mode", "Co-op")
	
	# Allow P2P connections to fallback to being relayed through Steam if needed
	var set_relay: bool = Steam.allowP2PPacketRelay(true)
	print("Allowing Steam to be relay backup: %s" % set_relay)
	
	# Show up invite dialogue
	Steam.activateGameOverlayInviteDialog(lobby_id)

func list_lobbies():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("name", "RH", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

# called once you requested data.
func _on_lobby_match_list(lobbies : Array):
	print("On lobby match list")
	var lobbies_container = GameManager.Instance.get_parent().join_lobby_container
	
	for lobby_child in lobbies_container.get_child(0).get_children():
		lobby_child.queue_free()
	
	for lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, "name")
		
		if lobby_name != "":
			var lobby_mode: String = Steam.getLobbyData(lobby, "mode")
			
			var lobby_button: Button = Button.new()
			lobby_button.set_text(lobby_name + " | " + lobby_mode)
			lobby_button.set_size(Vector2(200, 30))
			lobby_button.add_theme_font_size_override("font_size", 8)
			
			var fv = FontVariation.new()
			fv.set_base_font(load("res://font/dogica/TTF/dogicapixel.ttf"))
			lobby_button.add_theme_font_override("font", fv)
			lobby_button.set_name("lobby_%s" % lobby)
			lobby_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			lobby_button.connect("pressed", Callable(self, "request_join_lobby").bind(lobby))
			
			lobbies_container.get_child(0).add_child(lobby_button)

func _on_join_requested(lobby_id: int, steam_id: int):
	print("on join requested " + str(lobby_id) + " : " + str(steam_id))

# request to join. (not yet joined)
func request_join_lobby(lobby_id = 0):
	steam_peer.connect_lobby(lobby_id)
	multiplayer.multiplayer_peer = steam_peer
	auth_label.text = "Joining jam session" 

# when you actually succesfully joined.
func _on_lobby_joined(lobby: int, permissions: int, locked: bool, response: int):
	if response != 1:
		# TODO: Throw errors here
		pass

#endregion

func add_player(id = 1, char_index : int = 0):
	var player
	match char_index:
		0:
			player = trebbie_scene.instantiate()
		1:
			player = bass_scene.instantiate()


	player.name = str(id)
	player_container.call_deferred("add_child", player, true)

func _add_to_list(node : Node):
	var new_player = node as BaseHero
	if new_player == null:
		printerr("Trying to add a non-hero to player list") 
		return
	# todo: move this to the game manager instead of in the net.
	GameManager.Instance.add_player_to_list(new_player)

func _connect_signals():
	# Player container
	player_container.child_entered_tree.connect(_add_to_list)
	
	_connect_steam_signals()
	
	# Godot signals
	multiplayer.peer_connected.connect(_on_peer_connect)
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_client_connect)
	multiplayer.server_disconnected.connect(_on_served_disconnected)

func _connect_steam_signals():
	if !use_steam: return
	
	if !steam_peer.lobby_created.is_connected(_on_lobby_created):
		steam_peer.lobby_created.connect(_on_lobby_created)
	if !Steam.lobby_match_list.is_connected(_on_lobby_match_list):
		Steam.lobby_match_list.connect(_on_lobby_match_list)
	if !Steam.lobby_joined.is_connected(_on_lobby_joined):
		## Find out why steam peer here doesnt work but Steam works.
		Steam.lobby_joined.connect(_on_lobby_joined)
	if !Steam.join_requested.is_connected(_on_join_requested):
		Steam.join_requested.connect(_on_join_requested)

#region UI
# id is the person u've connected to
func _on_peer_connect(id):
	if multiplayer.is_server():
		friend_label.text = str(id) + " connected"
	else:
		friend_label.text = "Connected to: " + str(id)
		
		if !use_steam: return
		# this is for client + steam (edge case)
		auth_label.text = "Client"
		id_label.text = str(multiplayer.get_unique_id())
		
		GameManager.Instance.change_ui()
		GameManager.Instance.show_character_select_screen()

#endregion UI
#region Helper functions
func get_player_count():
	return GameManager.Instance.players.size()

func hide_ui():
	net_ui.visible = false
	label_timer.start(label_duration)
func show_ui():
	net_ui.visible = true
	auth_label.show()
	id_label.show()
	friend_label.show()
#endregion

# when we disconnect, we remove the gm scene and reload it in
func _on_peer_disconnect(_id):
	# Add disconnect from lobby when restarting
	
	if multiplayer.is_server():
		print("Client: "+ str(_id) + " disconnected")
	else:
		print("Server: " + str(_id) + " disconnected")
	GameManager.Instance.reset_game()

func _on_connection_failed():
	pass

# only on clientside
func _on_client_connect():
	pass

func _on_served_disconnected():
	pass

func _on_label_timer_timeout() -> void:
	auth_label.hide()
	id_label.hide()
	friend_label.hide()
