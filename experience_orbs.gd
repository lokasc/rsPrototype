extends Node2D

# Speed of the xp orb going towards the players
var speed = 1

var collected : bool = false

# Getting the player who collected the xp orb
var character : CharacterBody2D

signal xp_collected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if collected == true:
		# The movement may be more fancy than just moving towards the players
		position = position.move_toward(character.position,speed)
		speed *= 1.01
		
		# Destroys the node when the player collects it
		if position == character.position:
			xp_collected.emit()
			queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	# Checks if the area is the pick up radius
	if area.is_in_group("pick_up") and collected == false:
		collected = true
		character = area.get_parent()
		
		# Connects to the player's character
		# There were repeated connects error if the check wasn't there
		if xp_collected.is_connected(character.on_xp_collected):
			return
		xp_collected.connect(character.on_xp_collected)
