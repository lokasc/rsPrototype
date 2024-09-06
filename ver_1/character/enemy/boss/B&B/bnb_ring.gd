class_name BnBRing
extends BossAbility

@export var is_tgt : bool = false

# This is changed by the main script.





func enter() -> void:
	super()
	
func exit() -> void:
	super() # starts cd here.

func update(_delta: float) -> void:
	super(_delta)
