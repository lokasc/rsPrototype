class_name BaseHero
extends BaseCharacter

### Handles all gameplay logic for the player. 
# Inherit this to create new hero.

#signals for ability/item conditions
signal on_ability_used
signal on_basic_attack
signal on_attack_hit
signal on_hit #enemy hit u
signal player_die #hero just die

const DECELERATION = 80

## FLAGS for player state
var IS_DEAD : bool = false
var IS_DOWNED : bool = false 

@onready var input : PlayerInput = $MultiplayerSynchronizer
var id

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
	id = name.to_int()
	set_multiplayer_authority(name.to_int())
	
	$ServerSynchronizer.set_multiplayer_authority(1)
	$MultiplayerSynchronizer.set_multiplayer_authority(name.to_int())
	
	# if im the guy contorlling this mf object.
	if multiplayer.get_unique_id() == get_multiplayer_authority():
		GameManager.Instance.ui.my_player = self
		
	
	_init_stats()
	current_health = char_stats.maxhp
	player_die.connect(on_player_die)

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

func on_xp_collected():
	GameManager.Instance.add_xp(1)

func take_damage(dmg):
	if !multiplayer.is_server(): return
	current_health -= dmg
	check_death()

func check_death():
	if current_health <= 0:
		player_die.emit()

func on_player_die():
	IS_DEAD = true
	input.canMove = false
	set_process(false)
	set_physics_process(false)
	
