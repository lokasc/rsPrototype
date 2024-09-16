class_name MinePortal
extends Node2D

# use this signal for visuals or audio cues when portal is unlocked
signal portal_unlocked

# Game flags
@export_category("Game flags")
@export var unlocked : bool
@export var started : bool = false

@export_category("POI Stats")
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
		stc_set_unlocked.rpc()
	current_progress += delta * unlock_speed

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !multiplayer.is_server(): return
	 
	if body.get_parent() is not BaseHero: return
	stc_start_mining.rpc()

@rpc("reliable", "call_local")
func stc_start_mining():
	started = true

@rpc("reliable", "call_local")
func stc_set_unlocked():
	unlocked = true
	portal_unlocked.emit()
