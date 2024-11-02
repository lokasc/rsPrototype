class_name Beethoven
extends BaseBoss

signal show_warning(dir, seconds)
signal hide_warning

signal request_assistance # asks Biano to start "covering fire"

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

@export var indicator : Sprite2D
@export_subgroup("abilities")
@export var idle : BossAbility
@export var zoning_strike : ZoningStrike 
@export var bodyguard : BeeBodyguard
@export var pump_fake : BossAbility
@export var dash : BossAbility

@export_subgroup("Stress Heuristic")
@export var stress_threshold : float = 500 
# This means that either you hit beethoven 7 times (500/0.7/100 = 7)  or 500/0.3 = 1666 dmg in one hit.
# WARNING: w1 + w2 must not exceed 1
@export var weight_1 : float = 0.7# hit count weight
@export var weight_2 : float = 0.3# total dmg weight


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

# process your states here
func _process(delta: float) -> void:
	super(delta)

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
	
	state_change_from_any("BeethovenDash")
	global_position = GameManager.Instance.get_player(player_id).global_position

func on_request_assistance():
	if current_state is BeeBodyguard: return
	
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
