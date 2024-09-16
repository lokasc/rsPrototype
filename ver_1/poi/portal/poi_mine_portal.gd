class_name MinePortal
extends Node2D

# use this signal for visuals or audio cues when portal is unlocked
signal portal_unlocked

# Game flags
@export_category("Game flags")
@export var unlocked : bool
@export var started : bool = false

@export_category("POI Information")
@export var teleport_end_location : Vector2 = Vector2.ZERO

@export_subgroup("POI Stats")
# progress is measured in seconds
@export var unlock_amount : float

# rate of unlocking
@export var unlock_speed : float = 1

var current_progress : float

func _process(delta: float) -> void:
	if !started: return
	
	if !unlocked:
		mining_logic(delta)

func mining_logic(delta : float):
	if current_progress >= unlock_amount:
		# Unlock the portal logic.
		if !multiplayer.is_server(): return
		stc_portal_unlocked.rpc()
	current_progress += delta * unlock_speed

func _on_start_trigger_area_entered(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	 
	if started: return
	if area.get_parent() is not BaseHero: return
	stc_start_mining.rpc()

func _on_teleport_trigger_area_entered(area: Area2D) -> void:
	if !started || !unlocked: return 
	if !multiplayer.is_server(): return
	
	
	print("Emit")
	# teleport player
	var hero = area.get_parent()
	if hero is not BaseHero || !hero: return
	
	hero.global_position = teleport_end_location
	
	
	pass # Replace with function body.

@rpc("reliable", "call_local")
func stc_start_mining():
	started = true
	$BeatSyncEffect.modulate = Color.WHITE
	$BeatSyncEffect.restart()

@rpc("reliable", "call_local")
func stc_portal_unlocked():
	unlocked = true
	portal_unlocked.emit()
	$BeatSyncEffect.scale = Vector2(10,10)
	$BeatSyncEffect.modulate = Color.CADET_BLUE
	$BeatSyncEffect.restart()
