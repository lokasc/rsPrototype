class_name Bassheart
extends BaseHero

@export_category("Stats")
@export var damage : float = 100
@export var max_hp : float = 100
@export var shields : float = 0
@export var speed : int = 150
@export var area_of_effect : float = 1
@export var pick_up_radius : int = 40
@export var heal_shield_gain : float = 0.05

@export_category("Passive")
@export var meter : int = 0
## Determines how much meter gained from damage
@export var meter_multiplier : float = 1
@export var is_empowered : bool = false

var is_personal_camera : bool = true

@onready var particles : GPUParticles2D = $Sprites/GPUParticles2D
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
	particles.emitting = false
	#Temporarily disable the camera lock
	if is_personal_camera == false:
		camera.enabled = false
		camera.zoom = Vector2.ONE

func _process(_delta:float) -> void:
	super(_delta)
	pick_up.shape.radius *= char_stats.pick
	# temporary way of seeing meter, will probably end up in UI
	$ProgressBar.value = meter
	if meter >= 100:
		is_empowered = true
		particles.emitting = true

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
	particles.emitting = false
