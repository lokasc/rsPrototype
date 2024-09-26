class_name WaitingLobby
extends Node2D

@export var cd_timer : Timer
@export var cd_label : Label
@export var cd_pb : ProgressBar
@export var countdown_time : float = 3
var no_players : int = 0

func _ready() -> void:
	reset_countdown()

func reset_countdown() -> void:
	cd_label.text = "Waiting for players"
	cd_pb.value = cd_pb.max_value
	cd_timer.stop()

func start_countdown() -> void:
	cd_timer.start(countdown_time)

func _on_start_zone_body_entered(body: Node2D) -> void:
	no_players += 1
	
	if no_players == GameManager.Instance.net.MAX_CLIENTS:
		start_countdown()

func _on_start_zone_body_exited(body: Node2D) -> void:
	no_players = max(0, no_players - 1)
	reset_countdown()

func _on_countdown_timeout() -> void:
	if !multiplayer.is_server(): return
	GameManager.Instance.start_game()

func turn_off_lobby() -> void:
	$StaticBody2D.process_mode = Node.PROCESS_MODE_DISABLED
	get_node("StartZone").set_deferred("monitorable", false)
	get_node("StartZone").set_deferred("monitoring", false)
	visible = false

func _process(delta: float) -> void:
	if !cd_timer.is_stopped():
		cd_label.text = "%.1f" % cd_timer.time_left
		cd_pb.value = cd_timer.time_left
