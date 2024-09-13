# meta-description: Skeleton for creating heroes
extends BaseHero

# Sets starting stats, called in enter tree, Overide this to modify it.
func _init_stats() -> void:
	super()

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree() -> void:
	super()

# Node initalization.
func _ready() -> void:
	super()

func _process(_delta: float) -> void:
	super(_delta)
	
	# Rotates attack based on mouse direction
	if input.is_use_mouse_auto_attack:
		basic_attack.look_at(input.mouse_pos)
	basic_attack.use_basic_attack()

# Movement is handled here by super class
func _physics_process(_delta:float) -> void:
	super(_delta)
