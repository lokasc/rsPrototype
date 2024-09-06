class_name BnBRing
extends BossAbility

@export var is_tgt : bool = false

# This is changed by the main script.


# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func enter() -> void:
	super()
	

func exit() -> void:
	super() # starts cd here.

func update(_delta: float) -> void:
	super(_delta)
