extends Node

# this script is autoloaded.
# A node is created with this script attached at launch
# it is also a singleton, you can access this everywhere.

const PACKET_READ_LIMIT: int = 32
var app_id : int = 480
var steam_id : int = 0
var steam_username : String = ""

# Lobbies
var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 2
var lobby_vote_kick: bool = false

func _init() -> void:
	OS.set_environment("SteamAppId", str(app_id))
	OS.set_environment("SteamGameId", str(app_id))

func init_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s" % initialize_response)
	
	if initialize_response['status'] > 0:
		print("Failed to initialize Steam, shutting down: %s" % initialize_response)
		get_tree().quit()
	
	steam_username = Steam.getPersonaName()
	steam_id = Steam.getSteamID()
	print(steam_username)
	
	# check if player owns the game.
	if !Steam.isSubscribed(): 
		printerr("Steam is not on, or we dont have this game")
		get_tree().quit()

func clear_steam() -> void:
	steam_username = ""
	steam_id = 0

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	
func _process(delta: float) -> void:
	Steam.run_callbacks()

func create_lobby() -> void:
	if lobby_id != 0: return
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)

func _on_lobby_created(_connect: int, this_lobby_id: int) -> void:
	if _connect == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(lobby_id, true)

		# Set some lobby data
		Steam.setLobbyData(lobby_id, "name", "Gramps' Lobby")
		Steam.setLobbyData(lobby_id, "mode", "GodotSteam test")

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)
