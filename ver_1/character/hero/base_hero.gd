class_name BaseHero
extends BaseCharacter

### Handles all gameplay logic for the player. 
# Inherit this to create new hero.

const DECELERATION = 80

@onready var input : PlayerInput = $MultiplayerSynchronizer

var xp : float # not sure how we calculate xp.... is the xp_to_lvl_up exponential or fixed? 

# STATEMACHINE
var states : Dictionary = {}
var current_state : BaseAbility
var initial_state : BaseAbility

@export_category("Actions")
@export var basic_attack : BaseAbility

@export_subgroup("Abilities")
@export var ability_1 : BaseAbility
@export var ability_2 : BaseAbility
@export var passive : BaseAbility
@export var ult : BaseAbility

@export_subgroup("Items & Stat slots")
@export var items : Array[BaseItem] = []

var pop_up

func _init():
	super()
	pass

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	$MultiplayerSynchronizer.set_multiplayer_authority(name.to_int())
	
	_init_stats()
	current_health = char_stats.maxhp

func _ready():
	_init_states()
	pop_up = $TextPopUp as TextPopUp

func _process(_delta):
	if current_state:
		current_state.update(_delta)

func _physics_process(_delta):
	if current_state:
		current_state.physics_update(_delta)

func on_state_change(state_old, state_new_name):
	if state_old != current_state:
		return
	
	var new_state = states.get(state_new_name.to_lower())
	if !new_state:
		return
	
	if current_state:
		current_state.exit()
	
	new_state.enter()
	current_state = new_state

### Overide this to modify the starting stats of your hero
func _init_stats():
	char_stats.atk = 100
	char_stats.spd = 400
	char_stats.maxhp = 100

func _init_states():
	_parse_abilities(basic_attack)
	
	if !initial_state:
		initial_state = basic_attack

	current_state = initial_state
	current_state.enter()
	_parse_abilities(ability_1)
	_parse_abilities(ability_2)
	_parse_abilities(ult)

func _parse_abilities(x : BaseAbility):
	if x:
		x.hero = self
		states[x.name.to_lower()] = x
		x.state_change.connect(on_state_change)
