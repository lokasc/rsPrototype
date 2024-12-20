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

signal enter_low_health # when you enter low health
signal exit_low_health # when you exit low health

const DECELERATION : int = 80

# Sprite direction
enum Facing {LEFT, RIGHT}
var sprite_dir : int
@onready var sprite : Node2D = $Sprites

## FLAGS for player state
var IS_DEAD : bool = false
var IS_DOWNED : bool = false
var IS_INVINCIBLE : bool = false 

var low_health_threshold : float = 0.3
var is_low_health : bool = false

@onready var input : PlayerInput = $MultiplayerSynchronizer

var id : int
var x_scale : float

# STATEMACHINE
var states : Dictionary = {}
var current_state : BaseAbility
var initial_state : BaseAbility

@export_category("Actions")
@export var basic_attack : BaseAbility

@export_subgroup("Abilities")
@export var ability_1 : BaseAbility
@export var ability_2 : BaseAbility
@export var ult : BaseAbility

@export_subgroup("Items & Stat slots")
@export var items : Array[BaseItem] = []
var item_holder : Node
@export var stat_cards : Array[BaseStatCard] = []

@export_subgroup("Animation")
@export var animator : AnimationPlayer

var pop_up : TextPopUp
var camera : PlayerCamera

# Shield variables
var shield_lost : float 	# The amount of shield lost after gaining
var shield_duration : float
var shield_time : float
var is_losing_shield : bool = false

# This variable is used with hero's damage to set ability damages
var initial_damage : float 

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
	
	# Connect_signals
	player_die.connect(to_clients_player_died)
	level_up.connect(on_level_up)
	enter_low_health.connect(on_enter_low_health)
	exit_low_health.connect(on_exit_low_health)

func _ready():
	super()
	_init_states()
	x_scale = sprite.scale.x # Stores scale.x
	
	# Get references
	pop_up = $TextPopUp as TextPopUp
	camera = $PlayerCamera as PlayerCamera
	item_holder = $ItemHolder as Node
	
	GameManager.Instance.ui.create_player_info_bar(self)
	
	if is_multiplayer_authority():
		# Set this camera to viewport if I'm controlling it
		camera.make_current()
		camera.target = self
		
		# Set UI
		GameManager.Instance.ui.set_ability_ui()
	else:
		camera.target = null

func _process(_delta:float) -> void:
	if current_state:
		current_state.update(_delta)
	process_items(_delta)
	if is_losing_shield:
		shield_time += _delta
		if shield_time >= shield_duration:
			lose_shield(shield_lost)
	set_sprite_direction()

func _physics_process(_delta:float) -> void:
	if current_state:
		current_state.physics_update(_delta)

func process_items(_delta:float) -> void:
	for item : BaseItem in items:
		item._update(_delta)

func on_state_change(state_old, state_new_name:String):
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

func gain_health(heal:float):
	if !multiplayer.is_server(): return
	if current_health + heal * char_stats.hsg < char_stats.maxhp:
		current_health += heal * char_stats.hsg
	else:
		current_health = char_stats.maxhp
	
	check_low_health()

func gain_shield(shield:float, duration:float):
	if !multiplayer.is_server(): return
	current_shield += shield * char_stats.hsg
	shield_lost = shield * char_stats.hsg
	shield_duration = duration
	is_losing_shield = true

func lose_shield(shield:float):
	if !multiplayer.is_server(): return
	if current_shield - shield < 0:
		current_shield = 0
	else:
		current_shield -= shield
	is_losing_shield = false
	shield_time = 0

func take_damage(dmg:float):
	if IS_INVINCIBLE || IS_DEAD: return
	if !multiplayer.is_server(): return
	# Player damage logic
	if current_shield == 0:
		current_health -= dmg/char_stats.arm
	elif dmg/char_stats.arm <= current_shield:
		current_shield -= dmg/char_stats.arm
	elif dmg/char_stats.arm > char_stats.shields:
		current_health -= (dmg/char_stats.arm - current_shield)
		current_shield = 0
	
	check_low_health()
	check_death()

func check_death():
	# ran on the server.
	if current_health <= 0:
		player_die.emit()

func to_clients_player_died():
	on_player_die.rpc()
	if multiplayer.is_server():
		GameManager.Instance.check_alive_players()
	
	# Currently, music is handled by the server 
	# TODO: Music handled by the client
	
	if GameManager.Instance.is_boss_battle: return
	if id == 1: GameManager.Instance.bc.change_bg(BeatController.BG_TRANSITION_TYPE.LOW_HP)
	else: GameManager.Instance.bc.stc_change_bg_music.rpc_id(id, BeatController.BG_TRANSITION_TYPE.LOW_HP)

#region low_health

# Emits to/from low health signal when entering or exiting a threshold 
# Edgecase: if you gain shields, you also exit low_health mode.
func check_low_health():
	if !is_low_health && (current_shield + current_health <= char_stats.maxhp * low_health_threshold):
		is_low_health = true
		enter_low_health.emit()
	elif is_low_health && (current_shield + current_health > char_stats.maxhp * low_health_threshold):
		is_low_health = false
		exit_low_health.emit()

func on_enter_low_health():
	# change bg
	# and modulate the screen a bit.
	# currently this is a bug that conflicts with the boss music tracks
	
	if GameManager.Instance.is_boss_battle: return
	
	if id == 1: GameManager.Instance.bc.change_bg(BeatController.BG_TRANSITION_TYPE.LOW_HP)
	else: GameManager.Instance.bc.stc_change_bg_music.rpc_id(id, BeatController.BG_TRANSITION_TYPE.LOW_HP)

func on_exit_low_health():
	# change bg
	if GameManager.Instance.is_boss_battle: return
	
	if id == 1: GameManager.Instance.bc.change_bg_from_local_to_global()
	else: GameManager.Instance.bc.stc_change_bg_to_global.rpc_id(id)

#endregion low_health

@rpc("call_local", "reliable", "any_peer")
func on_player_die():
	# ran to all. 
	IS_DEAD = true
	input.canMove = false
	set_process(false)
	set_physics_process(false)

func is_alive() -> bool:
	return !(IS_DOWNED || IS_DEAD)

func set_sprite_direction():
	# Changing the sprite direction to the last moved direction
	
	# world space to camera space
	var mouse_pos_from_hero_pos = input.mouse_pos + input.CAMERA_OFFSET
	
	if mouse_pos_from_hero_pos.x <0:
		sprite_dir = Facing.LEFT
	elif mouse_pos_from_hero_pos.x >0:
		sprite_dir = Facing.RIGHT
	else:
		sprite_dir = Facing.RIGHT
	match sprite_dir:
		Facing.LEFT:
			sprite.scale.x = -1 * x_scale
		Facing.RIGHT:
			sprite.scale.x = x_scale

func get_atk() -> float:
	return char_stats.atk

func get_atk_mul() -> float:
	return char_stats.atk_mul

func get_total_dmg() -> float:
	return char_stats.atk_mul * char_stats.atk
# Logic for leveling up, perhaps max_hp increase...
func on_level_up(_new_level) -> void:
	# use new_level as x value to get the new hp as y value on the curve.
	#current_health = char_stats.maxhp
	pass

# add an item, call from GM
func add_item(action_index : int) -> void:
	if items.size() == 4: return
	
	var scene = GameManager.Instance.action_list.get_action_resource(action_index) as PackedScene
	var new_item = scene.instantiate() as BaseItem
	
	new_item.hero = self
	items.append(new_item)
	item_holder.add_child(new_item)
	
	GameManager.Instance.ui.set_item_ui(new_item, self)

func add_stat(index : int) -> void:
	var new_stat = GameManager.Instance.action_list.get_new_class_script(index)
	
	stat_cards.append(new_stat)
	new_stat.hero = self
	new_stat._upgrade()
	
	GameManager.Instance.ui.set_stat_ui(new_stat, self)


func get_stat(index : int) -> BaseStatCard:
	var new_stat_name = GameManager.Instance.action_list.get_new_class_script(index).get_class_name()
	for _stat_card : BaseStatCard in stat_cards:
		if _stat_card.get_class_name() == new_stat_name:
			return _stat_card
	return null

func upgrade_stat(index : int) -> void:
	var new_stat_name = GameManager.Instance.action_list.get_new_class_script(index).get_class_name()
	for _stat_card : BaseStatCard in stat_cards:
		if _stat_card.get_class_name() == new_stat_name:
			_stat_card._upgrade()

func has_stat(index : int) -> bool:
	var new_stat_name = GameManager.Instance.action_list.get_new_class_script(index).get_class_name()
	for _stat_card : BaseStatCard in stat_cards:
		if _stat_card.get_class_name() == new_stat_name:
			return true
	return false

func remove_item(_name) -> void:
	return

func has_item(_index : int) -> bool:
	var new_item_name = GameManager.Instance.action_list.get_new_class_script(_index).get_class_name()
	for _item : BaseItem in items:
		if _item.get_class_name() == new_item_name:
			return true
	return false

func get_action(new_action : BaseAction) -> BaseAction:
	# Parse Items first.
	for _item : BaseAction in items:
		if _item.get_class_name() == new_action.get_class_name():
			return _item
	
	# Then parse stats
	for _stat : BaseAction in stat_cards:
		if _stat.get_class_name() == new_action.get_class_name():
			return _stat
	
	# Parse attack, abilities, ultimates.
	if basic_attack && basic_attack.get_class_name() == new_action.get_class_name():
		return basic_attack
	if ability_1 && ability_1.get_class_name() == new_action.get_class_name():
		return ability_1
	if ability_2 && ability_2.get_class_name() == new_action.get_class_name():
		return ability_2
	if ult && ult.get_class_name() == new_action.get_class_name():
		return ult
	else:
		# If nothing is found, return null
		return null

func upgrade_item(item) -> void:
	for _item : BaseItem in items:
		if _item.get_class_name() == item.get_class_name():
			_item._upgrade()

func is_stats_full() -> bool:
	if stat_cards.size() >= 4:
		return true
	else:
		return false

func is_items_full() -> bool:
	if items.size() >= 4:
		return true
	else:
		return false

@rpc("any_peer", "call_local")
func teleport(gpos : Vector2):
	global_position = gpos
