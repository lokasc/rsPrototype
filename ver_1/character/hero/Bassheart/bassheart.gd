class_name Bassheart
extends BaseHero

@export_category("Stats")
## The damage the attack does, it also affects damage done by other abilities and items
@export var damage : float = 70

## The maximum hp the player has
@export var max_hp : float = 100

## The amount of shields the hero starts with
@export var shields : float = 0

## The movement speed of the hero
@export var speed : int = 150

## The cooldown of all actions (attack, abilities and items)
@export var cooldown : float = 1.0

## The area of effect of all actions (attack, abilities and items)
@export var area_of_effect : float = 1.0

## The radius of the circle that experience orbs get picked up by the player
@export var pick_up_radius : int = 40

## The multiplier applied when heal and shield is gain
@export var heal_shield_gain : float = 1

## The percentage of damage that is healed by the player
@export var lifesteal : float = 0.05

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
	initial_damage = damage
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
	char_stats.cd = cooldown
	char_stats.lifesteal = lifesteal

func take_damage(dmg) -> void:
	super(dmg)
	if not IS_INVINCIBLE:
		meter += dmg * meter_multiplier

func reset_meter() -> void:
	meter = 0
	is_empowered = false
	particles.emitting = false
