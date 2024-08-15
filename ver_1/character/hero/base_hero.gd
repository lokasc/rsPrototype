class_name BaseHero
extends BaseCharacter

### This handles the logic for the player. Inherit this to create new hero.

@onready var input : PlayerInput = $MultiplayerSynchronizer

const DECELERATION = 80
var pop_up

@export_category("Actions")
@export var basic_attack : BaseAbility

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

