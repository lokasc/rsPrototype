class_name Beethoven
extends BaseBoss

signal show_warning(dir, seconds)
signal hide_warning

signal request_assistance # asks Biano to start "covering fire"

var time_to_start_dance_sequence : float# The exact time when the solo starts. (8s + 128s)
var first_solo_time : float # How long the first solo lasts
var second_solo_time : float
var duo_solo_time : float

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

@export var indicator : Sprite2D
@export_subgroup("abilities")
@export var idle : BossAbility
@export var zoning_strike : ZoningStrike 
@export var bodyguard : BeeBodyguard
@export var pump_fake : BossAbility
@export var dash : BossAbility
@export_subgroup("Dance")
@export var idle_dance : BossAbility
@export var solo_dance : BossAbility
@export var duo_dance : BossAbility

@export_subgroup("Stress Heuristic")
@export var stress_threshold : float = 500 
# This means that either you hit beethoven 7 times (500/0.7/100 = 7)  or 500/0.3 = 1666 dmg in one hit.
# WARNING: w1 + w2 must not exceed 1
@export var weight_1 : float = 0.7# hit count weight
@export var weight_2 : float = 0.3# total dmg weight

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

var current_stress : float = 0
var hit_count : int = 0
var total_dmg_taken : float = 0# in this current phase until we take another action
var request_cd : float = 20 # how long until you can request again (well if you keep on calling request, you will break the game)

# Stress formula: w1 * num_of_attacks * 100 + w2 * total_dmg_done
# where w1 + w2 == 1
# the phase is within the current phase
# resets once idle turns into something other state.

var ally : BaseBoss

func _enter_tree() -> void:
	super()
	char_id = 22
	assign_duo_boss()
	show_warning.connect(on_show_warning)
	hide_warning.connect(on_hide_warning)

func _ready() -> void:
	super()
	init_duo_signals()
	indicator.hide()
	sprite = $Sprite2D
	x_scale = sprite.scale.x
	changed_from_idle.connect(reset_stress)
	hit.connect(update_stress)
	
	start_time = ally.start_time
	time_to_start_dance_sequence = ally.time_to_start_dance_sequence
	first_solo_time = ally.first_solo_time
	second_solo_time = ally.second_solo_time
	duo_solo_time = ally.duo_solo_time
	
	GameManager.Instance.bc.mimic_looped.connect(check_for_looping)

func _process(delta: float) -> void:
	super(delta)
	if get_time_passed() >= start_time + time_to_start_dance_sequence && !requested:
		requested = true
		GameManager.Instance.start_dance_sequence()
		state_change_from_any("IdleDance")
		
		#print("start_dance_sequence")
		if looped_times > 0:
			print("WE LOOP STARTED",get_time_passed())
		
	if !requested_second_solo && requested && get_time_passed()  >= start_time + time_to_start_dance_sequence + first_solo_time:
		requested_second_solo = true
		GameManager.Instance.start_second_solo()
		state_change_from_any("SoloDance")
		#print("start_second_solo")
		#print((GameManager.Instance.bc.time + (looped_times*mimic_track_time)))
	#
	if !requested_duo_dance && requested_second_solo && get_time_passed()>= start_time + time_to_start_dance_sequence + first_solo_time + second_solo_time:
		requested_duo_dance = true
		GameManager.Instance.start_dance_duo()
		state_change_from_any("DuoDance")
		#state_change_from_any("IdleDance") # need to rechange this to DuoDance (when implemented).
		#print("start_dance_duo")
		#print((GameManager.Instance.bc.time + (looped_times*mimic_track_time)))
	
	# End the last sequence.
	if !requested_end && requested_duo_dance && get_time_passed() >= start_time + time_to_start_dance_sequence + first_solo_time + second_solo_time + duo_solo_time:
		requested_end = true
		GameManager.Instance.end_dance_sequence()
		state_change_from_any("BeethovenIdle")
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

func check_for_looping():
	looped_times += 1

func get_time_passed() -> float:
	return GameManager.Instance.bc.time + looped_times * mimic_track_time

func _physics_process(delta : float) -> void:
	if frozen: return
	super(delta)

#override this to add your states in, executed in enter_tree
func _init_states():
	_parse_abilities(idle)
	_parse_abilities(zoning_strike)
	_parse_abilities(bodyguard)
	_parse_abilities(pump_fake)
	_parse_abilities(dash)
	_parse_abilities(idle_dance)
	_parse_abilities(solo_dance)
	_parse_abilities(duo_dance)
	super()


#region init
func assign_duo_boss():
	var other : BaseBoss = GameManager.Instance.spawner.get_enemy_from_id(21)
	# other hasn't loaded in, let other assign us. 
	if other == null: 
		print("cant find other unit")
		return
	#print("B",other.char_id)
	
	# assign for both
	other.ally = self
	ally = other


func init_duo_signals():
	if ally == null: return
	ally.escape.hit.connect(try_follow_up)
	ally.request_assistance.connect(on_request_assistance)
	ally.init_duo_signals() # IMPORTANT: BIANO MUST SPAWN BEFORE BEETHOVEN

# Displays warning symbol when about to attack.
func on_show_warning(pos, seconds) -> void:
	indicator.show()
	indicator.look_at(pos)
	
	if seconds == 0: return
	$WarningTimer.start(seconds)

func on_hide_warning() -> void:
	indicator.hide()

func _on_warning_timer_timeout() -> void:
	indicator.hide()
	pass
#endregion

# need to decide heuristics but for now we always follow up.
func try_follow_up(player_id):
	if current_state.name == "BeeBodyguard": return
	if current_state == duo_dance || current_state == idle_dance || current_state == solo_dance: return
	state_change_from_any("BeethovenDash")
	global_position = GameManager.Instance.get_player(player_id).global_position

func on_request_assistance():
	if current_state is BeeBodyguard: return
	if current_state == duo_dance || current_state == idle_dance || current_state == solo_dance: return
	state_change_from_any("BeeBodyguard")

#region stress & assistance
func reset_stress():
	current_stress = 0
	hit_count = 0
	total_dmg_taken = 0

func update_stress(p_dmg):
	hit_count += 1
	total_dmg_taken += p_dmg
	
	current_stress = hit_count*100 * weight_1 + total_dmg_taken * weight_2
	
	if current_stress >= stress_threshold:
		request_assistance.emit()
#endregion
