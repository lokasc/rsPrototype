extends Node2D

@export var dmg : float # connct to boss...
@export var spd : float # connct to boss...

# we will try to reuse this piece of code for both pRojectiles.

func _enter_tree() -> void:
	pass

func _ready() -> void:
	return
	print(str(multiplayer.is_server()) + " : " + str(dmg))

func _physics_process(delta: float) -> void:
	global_position += transform.y * delta * spd
