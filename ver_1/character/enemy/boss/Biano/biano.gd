class_name Biano
extends BaseBoss

signal request_assistance
signal died

@export var time_to_start_dance_sequence : float # The exact time when the solo starts.
@export var solo_frequency : float = 16 # How long each solo lasts (16Bars for first two)
var requested : bool
var requested_second_solo : bool
var requested_duo_dance : bool
var requested_end : bool

@export_subgroup("abilities")
@export var idle : BossAbility
@export var covering_fire : BossAbility
@export var rain : BossAbility # use BnBRain to switch due to file name
@export var escape : BossAbility

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
	arena_walls.reparent(GameManager.Instance.map)
	arena_walls.global_scale = Vector2(0.5, 0.5)
	GameManager.Instance.map.get_node("ArenaBuildings").visible = true

# process your states here
func _process(delta: float) -> void:
	super(delta)
	#print(GameManager.Instance.bc.time, " : ", multiplayer.is_server())
	if GameManager.Instance.bc.time >= time_to_start_dance_sequence && !requested:
		requested = true
		GameManager.Instance.start_dance_sequence()
	
	if !requested_second_solo && requested && GameManager.Instance.bc.time >= time_to_start_dance_sequence + solo_frequency:
		requested_second_solo = true
		GameManager.Instance.start_second_solo()
	
	if !requested_duo_dance && requested_second_solo && GameManager.Instance.bc.time >= time_to_start_dance_sequence + solo_frequency + solo_frequency:
		requested_duo_dance = true
		GameManager.Instance.start_dance_duo()
	
	if !requested_end && requested_duo_dance && GameManager.Instance.bc.time >= time_to_start_dance_sequence + solo_frequency + solo_frequency + solo_frequency:
		requested_end = true
		GameManager.Instance.end_dance_sequence()

#override this to add your states in 
func _init_states():
	_parse_abilities(idle)
	_parse_abilities(covering_fire)
	_parse_abilities(rain)
	_parse_abilities(escape)
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
	state_change_from_any("BianoCoveringFire")

func on_request_assistance():
	if current_state.name == "BianoEscapeFall": return
	state_change_from_any("BianoCoveringFire")

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

#region dance battle
# logic for dance here.
# always pick the server, and let them have no eyes.
func execute_first_solo():
	pass

#endregion
