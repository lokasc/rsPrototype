class_name Trebbie
extends BaseHero

enum Facing {LEFT, RIGHT}

var sprite_dir : int

@export var pick_up_radius : int = 40
@export var current_xp : int = 0

@onready var pick_up : CollisionShape2D = $PickUpRadius/CollisionShape2D
@onready var sprite : Sprite2D = $Sprite2D
@onready var levels = $LevelBar

func _enter_tree():
	super()
	pass

func _ready():
	super()
	initial_state = basic_attack
	pick_up.shape.radius = pick_up_radius

func _process(_delta):
	super(_delta)
	levels.value = current_xp
	

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
	char_stats.maxhp = 1000
	char_stats.spd = 700
	char_stats.aoe = 2
	char_stats.atk = 100

func on_xp_collected():
	current_xp += 1
