class_name BaseHero
extends BaseCharacter

### Handles all gameplay logic for the player. 
# Inherit this to create new hero.

#signals for ability/item conditions
signal ability_used(name)
signal on_basic_attack
signal on_attack_hit
signal on_hit #enemy hit u
signal player_die() #hero just die

const DECELERATION = 80

# Sprite direction
enum Facing {LEFT, RIGHT}
var sprite_dir : int
@onready var sprite : Sprite2D = $Sprite2D

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

@export_subgroup("Animation")
@export var animator : AnimationPlayer

var pop_up : TextPopUp
var camera : PlayerCamera

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
	player_die.connect(to_clients_player_died)

func _ready():
	super()
	_init_states()
	
	# Get references
	pop_up = $TextPopUp as TextPopUp
	camera = $PlayerCamera as PlayerCamera
	
	# Set this camera to viewport if I'm controlling it
	if is_multiplayer_authority():
		camera.make_current()

func _process(_delta):
	if current_state:
		current_state.update(_delta)

func _physics_process(_delta):
	if current_state:
		current_state.physics_update(_delta)
	sprite_direction()

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
	char_stats.hsg = 0.01

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

func gain_health(heal):
	if !multiplayer.is_server(): return
	if current_health + heal < char_stats.maxhp:
		current_health += heal
	else:
		current_health = char_stats.maxhp
	
func take_damage(dmg):
	if !multiplayer.is_server(): return
	current_health -= dmg
	check_death()

func check_death():
	if current_health <= 0:
		player_die.emit()

func to_clients_player_died():
	on_player_die.rpc()

@rpc("call_local", "reliable")
func on_player_die():
	IS_DEAD = true
	input.canMove = false
	set_process(false)
	set_physics_process(false)

func is_alive() -> bool:
	return !(IS_DOWNED || IS_DEAD)

func sprite_direction():
	# Changing the sprite direction to the last moved direction
	if input.direction.x <0:
		sprite_dir = Facing.LEFT
	elif input.direction.x >0:
		sprite_dir = Facing.RIGHT
	match sprite_dir:
		0:
			sprite.scale.x = -1
		1:
			sprite.scale.x = 1
