class_name Enemy
extends CharacterBody2D

## Base class for all enemy types.
## Has a position and health.

@export var health : float

func _ready():
	pass

func _process(_delta):
	pass

# Override this to change the calculation of taking damage.
func _on_hit(dmg):
	health -= dmg
	print("ouch ", health)
	
	if health <= 0: # Kill enemy
		queue_free()

func _decide(target = null):
	pass

