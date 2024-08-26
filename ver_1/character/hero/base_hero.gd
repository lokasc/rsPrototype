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
signal level_up(new_level)

const DECELERATION : int = 80

# Sprite direction
enum Facing {LEFT, RIGHT}
var sprite_dir : int
@onready var sprite : Sprite2D = $Sprite2D

## FLAGS for player state
var IS_DEAD : bool = false
var IS_DOWNED : bool = false
var IS_INVINCIBLE : bool = false 

@onready var input : PlayerInput = $MultiplayerSynchronizer

var id : int

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
var item_holder : Node

@export_subgroup("Animation")
@export var animator : AnimationPlayer

var pop_up : TextPopUp
var camera : PlayerCamera

# Shield variables
var shield_lost : int
var shield_duration : float
var shield_time : float
var is_losing_shield : bool = false

func _init():
	super()
	pass

func _enter_tree():
	id = name.to_int()
	set_multiplayer_authority(name.to_int())
	
	# only server can determine health, items and statuses.
	$ServerSynchronizer.set_multiplayer_authority(1)
	$StatusHolder.set_multiplayer_authority(1)
	$ItemHolder.set_multiplayer_authority(1)
	
	# let control be on the player
	$MultiplayerSynchronizer.set_multiplayer_authority(name.to_int())
	
	# if im the guy contorlling this mf object.
	if multiplayer.get_unique_id() == get_multiplayer_authority():
		GameManager.Instance.local_player = self

	
	_init_stats()
	current_health = char_stats.maxhp
	current_shield = char_stats.shields
	player_die.connect(to_clients_player_died)
	level_up.connect(on_level_up)

func _ready():
	super()
	_init_states()
	
	# Get references
	pop_up = $TextPopUp as TextPopUp
	camera = $PlayerCamera as PlayerCamera
	item_holder = $ItemHolder as Node
	# Set this camera to viewport if I'm controlling it
	if is_multiplayer_authority():
		camera.make_current()

func _process(_delta) -> void:
	if current_state:
		current_state.update(_delta)
	process_items(_delta)
	if is_losing_shield:
		shield_time += _delta
		if shield_time >= shield_duration:
			lose_shield(shield_lost)

func _physics_process(_delta) -> void:
	if current_state:
		current_state.physics_update(_delta)
	sprite_direction()

func process_items(_delta) -> void:
	for item : BaseItem in items:
		item._update(_delta)

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

func gain_shield(shield, duration):
	if !multiplayer.is_server(): return
	current_shield += shield
	shield_lost = shield
	shield_duration = duration
	is_losing_shield = true

func lose_shield(shield):
	if !multiplayer.is_server(): return
	if current_shield - shield < 0:
		current_shield = 0
	else:
		current_shield -= shield
	is_losing_shield = false
	shield_time = 0

func take_damage(dmg):
	if !multiplayer.is_server(): return
	if IS_INVINCIBLE: return
	# Player damage logic
	if current_shield == 0:
		current_health -= dmg
	elif dmg <= current_shield:
		current_shield -= dmg
	elif dmg > char_stats.shields:
		current_health -= (dmg - current_shield)
		current_shield = 0
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

func get_atk() -> int:
	return char_stats.atk

func get_atk_mul() -> int:
	return char_stats.atk_mul

# Logic for leveling up, perhaps max_hp increase...
func on_level_up(new_level) -> void:
	# use new_level as x value to get the new hp as y value on the curve.
	#current_health = char_stats.maxhp
	pass

# add an item, call from GM
func add_item(_item : BaseItem) -> void:
	var filename : String = GameManager.Instance.serialize(_item) + ".tscn"
	var new_item = load("res://ver_1/actions/items/" + filename).instantiate() as BaseItem
	_item.queue_free()
	
	new_item.hero = self
	items.append(new_item)
	item_holder.add_child(new_item)

func remove_item(name) -> void:
	return

func has_item(new_item : BaseItem) -> bool:
	for _item : BaseItem in items:
		if _item.get_class_name() == new_item.get_class_name():
			return true
	return false

func get_action(new_action : BaseAction) -> BaseAction:
	# Parse Items first.
	for _item : BaseAction in items:
		if _item.get_class_name() == new_action.get_class_name():
			return _item
	# Parse attack, abilities, passive, ultimates.
	if basic_attack && basic_attack.get_class_name() == new_action.get_class_name():
		return basic_attack
	if ability_1 && ability_1.get_class_name() == new_action.get_class_name():
		return ability_1
	if ability_2 && ability_2.get_class_name() == new_action.get_class_name():
		return ability_2
	if ult && ult.get_class_name() == new_action.get_class_name():
		return ult
	if passive && passive.get_class_name() == new_action.get_class_name():
		return passive
	else:
		return null

func upgrade_item(item) -> void:
	for _item : BaseItem in items:
		if _item.get_class_name() == item.get_class_name():
			_item._upgrade()
