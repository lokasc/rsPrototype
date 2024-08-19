class_name Trebbie
extends BaseHero

enum Facing {LEFT, RIGHT}

var sprite_dir : int

#Currently doesn't work in multiplayer
@export var personal_camera : bool = true

@export_category("Stats")
@export var damage = 100
@export var max_hp = 100
@export var speed = 200
@export var area_of_effect = 2
@export var pick_up_radius : int = 40

@onready var pick_up : CollisionShape2D = $PickUpRadius/CollisionShape2D
@onready var sprite : Sprite2D = $Sprite2D

func _enter_tree():
	super()
	pass

func _ready():
	super()
	initial_state = basic_attack
	pick_up.shape.radius = pick_up_radius
	
	#Temporarily disable the camera lock
	if personal_camera == false:
		$PlayerCamera.enabled = false
		$PlayerCamera.zoom = Vector2.ONE

func _process(_delta):
	super(_delta)

func _physics_process(_delta):
	super(_delta)
	
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


### Overide this to modify the starting stats of your hero
func _init_stats():
	super()
	char_stats.maxhp = max_hp
	char_stats.spd = speed
	char_stats.aoe = area_of_effect
	char_stats.atk = damage
