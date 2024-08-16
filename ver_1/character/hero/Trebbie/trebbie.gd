class_name Trebbie
extends BaseHero

enum Facing {LEFT, RIGHT}

var sprite_dir : int

@onready var sprite : Sprite2D = $Sprite2D

func _enter_tree():
	super()
	pass

func _ready():
	super()

func _process(_delta):
	super(_delta)
	
	# TODO: Move this piece of code into trebbie's attack
	if input.is_use_mouse_auto_attack:
		basic_attack.look_at(input.mouse_pos)
	basic_attack.use_ability()

func _physics_process(_delta):
	super(_delta)
	
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
