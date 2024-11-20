class_name Biano
extends BaseBoss

signal request_assistance
signal died

@export var time_to_start_dance_sequence : float = 128# The exact time when the solo starts. (8s + 128s)
@export var first_solo_time : float = 32 # How long the first solo lasts
@export var second_solo_time : float = 36
@export var duo_solo_time : float = 36
var start_time
var track_duration : float = 232 # to check for looping (without the intro) 232
var looped_times : int = 0
var mimic_track_time : float = 320.05 # mimic length
var mimic_previous_time : float = 0
var current_mimic_time : float = 0

var requested : bool
var requested_second_solo : bool
var requested_duo_dance : bool
var requested_end : bool

@export_subgroup("abilities")
@export var idle : BossAbility
@export var covering_fire : BossAbility
@export var rain : BossAbility # use BnBRain to switch due to file name
@export var escape : BossAbility
@export_subgroup("Dance")
@export var idle_dance : BossAbility
@export var solo_dance : BossAbility
@export var duo_dance : BossAbility

@export_subgroup("Stress Heuristic")
@export var stress_threshold : float
# WARNING: w1 + w2 must not exceed 1
@export var weight_1 : float # hit count weight
@export var weight_2 : float # total dmg weight

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox
@onready var arena_walls = $ArenaWalls

var current_stress : float = 0
var hit_count : int = 0
var total_dmg_taken : float = 0# in this current phase until we take another action
var request_cd : float = 20 # how long until you can request again (well if you keep on calling request, you will break the game)

# Stress formula: w1 * num_of_attacks * 100 + w2 * total_dmg_done
# where w1 + w2 == 1
# the phase is within the current phase
# resets once idle turns into something other state.

var falling_tiles_count : int = 0 # the number of times falling tiles is use before a slam is done.
var ally : BaseBoss

func _enter_tree() -> void:
	super()
	char_id = 21
	assign_duo_boss()
	requested = false
	
func _ready() -> void:
	super()
	init_duo_signals()
	sprite = $Sprite2D
	x_scale = sprite.scale.x
	changed_from_idle.connect(reset_stress)
	hit.connect(update_stress)
	
	# Activate and bring out arena walls
	arena_walls.call_deferred("reparent", GameManager.Instance.map)
	arena_walls.global_scale = Vector2(0.5, 0.5)
	GameManager.Instance.map.get_node("ArenaBuildings").visible = true
	GameManager.Instance.bc.change_bg(BeatController.BG_TRANSITION_TYPE.BNB_PHASE_TWO)
	start_time = GameManager.Instance.bc.time + 8 # account for intro
	GameManager.Instance.bc.mimic_looped.connect(check_for_looping)


# process your states here
func _process(delta: float) -> void:
	super(delta)
	if get_time_passed() >= start_time + time_to_start_dance_sequence && !requested:
		requested = true
		GameManager.Instance.start_dance_sequence()
		state_change_from_any("SoloDance")
		
		print("start_dance_sequence")
		if looped_times > 0:
			print("WE LOOP STARTED",get_time_passed())
		
	if !requested_second_solo && requested && get_time_passed()  >= start_time + time_to_start_dance_sequence + first_solo_time:
		requested_second_solo = true
		GameManager.Instance.start_second_solo()
		state_change_from_any("IdleDance")
		#print("start_second_solo")
		#print((GameManager.Instance.bc.time + (looped_times*mimic_track_time)))
	#
	if !requested_duo_dance && requested_second_solo && get_time_passed()>= start_time + time_to_start_dance_sequence + first_solo_time + second_solo_time:
		requested_duo_dance = true
		GameManager.Instance.start_dance_duo()
		state_change_from_any("DuoDance")
		#print("start_dance_duo")
		#print((GameManager.Instance.bc.time + (looped_times*mimic_track_time)))
	
	# End the last sequence.
	if !requested_end && requested_duo_dance && get_time_passed() >= start_time + time_to_start_dance_sequence + first_solo_time + second_solo_time + duo_solo_time:
		requested_end = true
		GameManager.Instance.end_dance_sequence()
		state_change_from_any("BianoIdle")
		#print("end_dance_sequence")
		#print((GameManager.Instance.bc.time + (looped_times*mimic_track_time)))
	
	# Check for looping and reset,
	if requested_end && get_time_passed() >= start_time + track_duration:
		start_time = get_time_passed()
		requested_end = false
		requested = false
		requested_duo_dance = false
		requested_second_solo = false
		#print("reseted")
		#print((GameManager.Instance.bc.time + (looped_times*mimic_track_time)))
func _physics_process(delta: float) -> void:
	super(delta)
	
func check_for_looping():
	looped_times += 1

func get_time_passed() -> float:
	return GameManager.Instance.bc.time + looped_times * mimic_track_time

#override this to add your states in 
func _init_states():
	_parse_abilities(idle)
	_parse_abilities(covering_fire)
	_parse_abilities(rain)
	_parse_abilities(escape)
	_parse_abilities(idle_dance)
	_parse_abilities(solo_dance)
	_parse_abilities(duo_dance)
	super()

func assign_duo_boss():
	var other : BaseBoss = GameManager.Instance.spawner.get_enemy_from_id(22)
	# other hasn't loaded in, let other assign us. 
	if other == null: return
	#print("P",other.char_id)
	# assign for both
	other.ally = self
	ally = other

func init_duo_signals():
	if ally == null: return
	ally.zoning_strike.hit.connect(try_follow_up)
	ally.request_assistance.connect(on_request_assistance)

func try_follow_up():
	if current_state.name == "BianoEscapeFall": return
	if current_state == duo_dance || current_state == idle_dance || current_state == solo_dance: return
	state_change_from_any("BianoCoveringFire")

func on_request_assistance():
	if current_state.name == "BianoEscapeFall": return
	if current_state == duo_dance || current_state == idle_dance || current_state == solo_dance: return
	state_change_from_any("BianoCoveringFire")

#region stress & assistance
func reset_stress():
	current_stress = 0
	hit_count = 0
	total_dmg_taken = 0

func update_stress(p_dmg):
	# dont let client decide on requesting assistance.
	if !multiplayer.is_server(): return
	hit_count += 1
	total_dmg_taken += p_dmg
	
	current_stress = hit_count*100 * weight_1 + total_dmg_taken * weight_2
	
	if current_stress >= stress_threshold:
		request_assistance.emit()
#endregion
