class_name Trebbie
extends BaseHero

#Currently doesn't work in multiplayer
@export var is_personal_camera : bool = true

@export_category("Stats")
@export var damage : int = 100
@export var max_hp : int = 100
@export var speed : int = 200
@export var area_of_effect : float = 2
@export var pick_up_radius : int = 40
@export var heal_shield_gain : float = 0.01

@onready var pick_up : CollisionShape2D = $PickUpRadius/CollisionShape2D

func _enter_tree():
	super()
	pass

func _ready():
	super()
	initial_state = basic_attack
	pick_up.shape.radius = pick_up_radius
	
	##Temporarily disable the camera lock
	#if is_personal_camera == false:
		#camera.enabled = false
		#camera.zoom = Vector2.ONE

func _process(_delta):
	super(_delta)

func _physics_process(_delta):
	super(_delta)


### Overide this to modify the starting stats of your hero
func _init_stats():
	super()
	char_stats.maxhp = max_hp
	char_stats.spd = speed
	char_stats.aoe = area_of_effect
	char_stats.atk = damage
	char_stats.hsg = heal_shield_gain
