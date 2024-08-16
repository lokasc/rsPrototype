class_name BaseHero
extends BaseCharacter

### Handles all gameplay logic for the player. 
# Inherit this to create new hero.

const DECELERATION = 80

@onready var input : PlayerInput = $MultiplayerSynchronizer

var xp : float # not sure how we calculate xp.... is the xp_to_lvl_up exponential or fixed? 

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
	pop_up = $TextPopUp as TextPopUp
	#add_to_group("players")

func _process(_delta):
	pass

func _physics_process(_delta):
	if input.direction:
		velocity = input.direction * char_stats.spd
	else:
		velocity = velocity.move_toward(Vector2.ZERO,DECELERATION)
	move_and_slide()

### Overide this to modify the starting stats of your hero
func _init_stats():
	char_stats.atk = 100
	char_stats.spd = 400
	char_stats.maxhp = 100
