extends Node2D


@onready var dummy = $Dummy
@onready var pop_up = $TextPopUp
func _ready() -> void:
	dummy.hit.connect(on_hit)
	pass 

func on_hit(dmg):
	pop_up.set_pop(str(dmg), dummy.global_position)
