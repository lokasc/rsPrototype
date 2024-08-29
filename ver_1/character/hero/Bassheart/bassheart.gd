class_name Bassheart
extends BaseHero

@export var is_personal_camera : bool = true

@export_category("Meter Stats")
@export var meter : int = 0
## Determines how much meter gained from damage
@export var meter_multiplier : float = 1
@export var is_empowered : bool = false

@export_category("Stats")
@export var damage : int = 100
@export var max_hp : int = 100
@export var shields : int = 0
@export var speed : int = 200
@export var area_of_effect : float = 2
@export var pick_up_radius : int = 40
@export var heal_shield_gain : float = 0.01

@onready var pick_up : CollisionShape2D = $PickUpRadius/CollisionShape2D

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree() -> void:
	super()

# Node initalization.
func _ready() -> void:
	super()
	initial_state = basic_attack
	pick_up.shape.radius = pick_up_radius
	#Temporarily disable the camera lock
	if is_personal_camera == false:
		camera.enabled = false
		camera.zoom = Vector2.ONE

func _process(_delta:float) -> void:
	super(_delta)
	# temporary way of seeing meter, will probably end up in UI
	$ProgressBar.value = meter
	if meter >= 100:
		is_empowered = true

# Movement is handled here by super class
func _physics_process(_delta:float) -> void:
	super(_delta)

### Overide this to modify the starting stats of your hero
func _init_stats() -> void:
	super()
	char_stats.maxhp = max_hp
	char_stats.spd = speed
	char_stats.aoe = area_of_effect
	char_stats.atk = damage
	char_stats.hsg = heal_shield_gain
	char_stats.shields = shields

func take_damage(dmg) -> void:
	super(dmg)
	if not IS_INVINCIBLE:
		meter += dmg * meter_multiplier

func reset_meter() -> void:
	meter = 0
	is_empowered = false
