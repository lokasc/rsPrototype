class_name BaseEnemy
extends BaseCharacter

# For inspector view only, cant modify class stats in inspector. 
@export_subgroup("Basic information")
@export var max_health : float
@export var speed : float
@export var dmg : float


# XP & Loot
@onready var loot = get_tree().get_first_node_in_group("loot")
@export var xp_worth = 1
@onready var xp_orb = load("res://experience_orbs.tscn")

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
	pass

# Export variables arent ready on innit
func _enter_tree():
	target = GameManager.Instance.players[0]
	_init_stats()

func take_damage(dmg):
	# Client prediction
	current_health -= dmg
	if current_health <= 0:
		death.rpc()

@rpc("unreliable_ordered", "call_local")
func death():
	for i in range(xp_worth):
		var new_xp = xp_orb.instantiate()
		loot.call_deferred("add_child", new_xp)
		new_xp.position = position + Vector2(randi_range(-5,5),randi_range(-5,5))
	queue_free()
