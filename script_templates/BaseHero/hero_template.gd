# meta-description: Skeleton for creating heroes
extends BaseHero

# Sets starting stats, called in enter tree, Overide this to modify it.
func _init_stats():
	super()

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree():
	super()

# Node initalization.
func _ready():
	super()

func _process(_delta):
	super(_delta)
	
	# Rotates attack based on mouse direction
	if input.is_use_mouse_auto_attack:
		basic_attack.look_at(input.mouse_pos)
	basic_attack.use_ability()

# Movement is handled here by super class
func _physics_process(_delta):
	super(_delta)
