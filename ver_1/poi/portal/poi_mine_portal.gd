class_name MinePortal
extends Node2D

# use this signal for visuals or audio cues when portal is unlocked
signal portal_unlocked

# Game flags
@export_category("Game flags")
@export var unlocked : bool
@export var started : bool = false

@export var ready_to_teleport : bool

@export_category("POI Information")
@export var teleport_locations : Array[Node2D]

@export_subgroup("POI Stats")
# progress is measured in seconds
@export var unlock_amount : float

# rate of unlocking
@export var unlock_speed : float = 1

# time to recharge
@export var recharge_time : float = 5

var current_progress : float = 0
var teleport_charges : int
var current_recharge_time : float

@onready var progress_bar : ProgressBar = $ProgressBar

func _ready() -> void:
	progress_bar.max_value = unlock_amount

func _process(delta: float) -> void:
	if !started: return
	
	if !unlocked:
		mining_logic(delta)
	else:
		#print(ready_to_teleport)
		#print(teleport_charges)
		recharge_logic(delta)

# Cool down on portal is dealt with on the server (for sync hassle sake)
func recharge_logic(delta : float):
	if !multiplayer.is_server(): return
	
	if ready_to_teleport: return
	
	# Reset teleport charges.
	if current_recharge_time >= recharge_time:
		current_recharge_time = 0
		teleport_charges = 2
		ready_to_teleport = true
		
	#print("charging!")
	current_recharge_time += delta
	#progress_bar.value = current_recharge_time


func mining_logic(delta : float):
	if current_progress >= unlock_amount:
		# Unlock the portal logic.
		if !multiplayer.is_server(): return
		stc_portal_unlocked.rpc()
	current_progress += delta * unlock_speed
	progress_bar.value = current_progress

func _on_start_trigger_area_entered(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	 
	if started: return
	if area.get_parent() is not BaseHero: return
	stc_start_mining.rpc()

func _on_start_trigger_area_exited(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	stc_stop_mining.rpc()

func _on_teleport_trigger_area_entered(area: Area2D) -> void:
	if !started || !unlocked: return 
	if !multiplayer.is_server(): return
	

	# teleport player
	var hero = area.get_parent()
	if hero is not BaseHero || !hero: return
	
	#Typecast
	hero = hero as BaseHero
	
	# The client determines the position of their character
	# we will need to use RPCs, regular set position would not work.
	
	if !ready_to_teleport: return
	teleport_charges -= 1
	if teleport_charges <= 0: 
		ready_to_teleport = false
	hero.teleport.rpc(decide_teleport_location())

# Currently, the algorithm is: Random
func decide_teleport_location() -> Vector2:
	if teleport_locations.size() == 0: return Vector2.ZERO
	
	var rand_loc_index : int = randi_range(0, teleport_locations.size() - 1)
	
	return teleport_locations[rand_loc_index].global_position

@rpc("reliable", "call_local")
func stc_stop_mining():
	started = false
	$BeatSyncEffect.modulate = Color.WHITE
	$BeatSyncEffect.emitting = false


@rpc("reliable", "call_local")
func stc_start_mining():
	started = true
	$BeatSyncEffect.modulate = Color.WHITE
	$BeatSyncEffect.emitting = true

@rpc("reliable", "call_local")
func stc_portal_unlocked():
	unlocked = true
	teleport_charges = 2
	ready_to_teleport = true
	portal_unlocked.emit()
	$BeatSyncEffect.scale = Vector2(10,10)
	$BeatSyncEffect.modulate = Color.CADET_BLUE
	$BeatSyncEffect.restart()
