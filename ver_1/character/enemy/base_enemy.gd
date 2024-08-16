class_name BaseEnemy
extends BaseCharacter

# For inspector view only, cant modify class stats in inspector. 
@export_subgroup("Basic information")
@export var max_health : float
@export var speed : float

var target : BaseHero

## Base class for all enemy types.
## Has a position and health.

func _init():
	super()

# Export variables arent ready on innit
func _enter_tree():
	char_stats.maxhp = max_health
	char_stats.spd = speed
	current_health = char_stats.maxhp

func take_damage(dmg):
	current_health -= dmg
	pass
