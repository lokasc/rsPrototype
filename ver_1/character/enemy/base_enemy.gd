class_name BaseEnemy
extends BaseCharacter

signal hit(dmg) # hit by enemy

# For inspector view only, cant modify class stats in inspector. 
@export_category("Basic information")
@export var max_health : float
@export var speed : float
@export var dmg : float

@export_subgroup("Status")
@export var can_move : bool
@export var frozen : bool

# XP & Loot
@export_subgroup("XP")
@export var xp_worth : int = 1
@export var xp_drop_spread : int
@onready var loot = get_tree().get_first_node_in_group("loot")
@onready var xp_orb = load("res://ver_1/game/spawn_system/experience_orbs.tscn")

var target : BaseHero

## Base class for all enemy types.
## Has a position and health.

func _init():
	super()

func _init_stats():
	char_stats.maxhp = max_health
	char_stats.spd = speed
	char_stats.atk = dmg
	current_health = char_stats.maxhp
	
	can_move = true
	frozen = false
	pass

# Export variables arent ready on innit
func _enter_tree():
	target = GameManager.Instance.players[0]
	_init_stats()

func take_damage(dmg):
	# Client prediction
	current_health -= dmg
	hit.emit(dmg)
	if current_health <= 0:
		death.rpc()

@rpc("unreliable_ordered", "call_local")
func death():
	for i in range(xp_worth):
		var new_xp = xp_orb.instantiate()
		loot.call_deferred("add_child", new_xp)
		new_xp.position = position + Vector2(randi_range(-xp_drop_spread,xp_drop_spread),randi_range(-xp_drop_spread,xp_drop_spread))
	queue_free()

func move_to_target(target = null):
	if target == null: return

# direction need to go towards
	var direction = global_position.direction_to(target.global_position)
	var distance = global_position.distance_to(target.global_position)
	
	if distance < 15:
		velocity = Vector2.ZERO
	else:
		velocity = direction * char_stats.spd
	
	if direction.x < 0:
		sprite.scale.x = x_scale
	elif direction.x > 0:
		sprite.scale.x = x_scale * -1
	else:
		sprite.scale.x = x_scale * -1
	move_and_slide()

