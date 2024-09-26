class_name MinePortal
extends Node2D

# use this signal for visuals or audio cues when portal is unlocked
signal portal_unlocked

# Game flags
@export_category("Game flags")
@export var unlocked : bool
@export var started : bool = false
@export var ready_to_teleport : bool
@export var ready_to_give_stats : bool

@export_category("POI Info")
# progress is measured in seconds
@export var unlock_amount : float

# rate of unlocking
@export var unlock_speed : float = 1

@export_group("POI Modes")
@export var teleportation : bool = false
@export var give_stats_bonuses: bool = true

@export_subgroup("Teleport Info")
# time to recharge
@export var recharge_time : float = 5

@export var teleport_locations : Array[Node2D]

@export_subgroup("Stats Bonus Info")
@export var aoe_increase : float 
@export var armour_increase : float 
@export var cooldown_decrease : float 
@export var damage_increase : float 
@export var duration_increase : float
@export var heal_and_shield_increase : float 
@export var max_hp_increase : float 
@export var music_multiplier_increase : float 
@export var pick_up_radius_increase : float 
@export var speed_increase : float 

@export_category("Debug")
@export var fast_unlock : bool

var current_progress : float = 0
var teleport_charges : int
var current_recharge_time : float
var bonus_given : bool = false

@onready var progress_bar : ProgressBar = $ProgressBar
@onready var vfx : GPUParticles2D = $BeatSyncEffect

func _ready() -> void:
	if fast_unlock:
		unlock_amount = 5
	progress_bar.max_value = unlock_amount

func _process(delta: float) -> void:
	if !started: return
	
	if !unlocked:
		mining_logic(delta)
	elif teleportation:
		#print(ready_to_teleport)
		#print(teleport_charges)
		recharge_logic(delta)
	elif give_stats_bonuses and !bonus_given:
		stat_bonus_logic()

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

func stat_bonus_logic():
	if !multiplayer.is_server(): return
	
	if !ready_to_give_stats: return
	
	if GameManager.Instance.net.MAX_CLIENTS == 1:
		increase_stats(GameManager.Instance.players[0])
	else:
		increase_stats(GameManager.Instance.players[0])
		increase_stats(GameManager.Instance.players[1])
	bonus_given = true

func increase_stats(player : BaseHero):
	var player_stats = player.char_stats
	player_stats.aoe += aoe_increase
	player_stats.arm += armour_increase
	player_stats.cd -= cooldown_decrease
	player_stats.atk += damage_increase
	player_stats.dur += duration_increase
	player_stats.hsg += heal_and_shield_increase
	player_stats.maxhp += max_hp_increase
	player_stats.mus += music_multiplier_increase
	player_stats.pick += pick_up_radius_increase
	player_stats.spd += speed_increase

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
	vfx.modulate = Color.WHITE
	vfx.emitting = false


@rpc("reliable", "call_local")
func stc_start_mining():
	started = true
	vfx.modulate = Color.WHITE
	vfx.emitting = true

@rpc("reliable", "call_local")
func stc_portal_unlocked():
	unlocked = true
	teleport_charges = 2
	ready_to_teleport = true
	ready_to_give_stats = true
	portal_unlocked.emit()
	vfx.scale = Vector2(10,10)
	vfx.modulate = Color.CADET_BLUE
	vfx.restart()
