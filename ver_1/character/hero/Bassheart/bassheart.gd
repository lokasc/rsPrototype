class_name Bassheart
extends BaseHero

@export var is_personal_camera : bool = true

@export_category("Stats")
@export var damage : int = 100
@export var max_hp : int = 100
@export var speed : int = 200
@export var area_of_effect : float = 2
@export var pick_up_radius : int = 40
@export var heal_shield_gain : float = 0.01

@onready var pick_up : CollisionShape2D = $PickUpRadius/CollisionShape2D

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree():
	super()

# Node initalization.
func _ready():
	super()
	initial_state = basic_attack
	pick_up.shape.radius = pick_up_radius
	
	#Temporarily disable the camera lock
	if is_personal_camera == false:
		camera.enabled = false
		camera.zoom = Vector2.ONE

func _process(_delta):
	super(_delta)

# Movement is handled here by super class
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

# this function overrides the base hero one because of the current sprite
# will be deleted after bassheart sprite is done
func sprite_direction():
	# Changing the sprite direction to the last moved direction
	if input.direction.x <0:
		sprite_dir = Facing.LEFT
	elif input.direction.x >0:
		sprite_dir = Facing.RIGHT
	match sprite_dir:
		0:
			sprite.scale.x = -0.156
		1:
			sprite.scale.x = 0.156
