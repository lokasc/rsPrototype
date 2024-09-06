class_name BnBRain
extends BossAbility

@export var is_tgt : bool = false

# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func enter() -> void:
	super()
	pass

func exit() -> void:
	super() # starts cd here.

func update(_delta: float) -> void:
	super(_delta)
	pass

func physics_update(_delta: float) -> void:
	super(_delta)
	pass
