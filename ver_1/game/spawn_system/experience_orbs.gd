extends Node2D

signal xp_collected
# Speed of the xp orb going towards the players
var speed : int = 1

var collected : bool = false

# Getting the player who collected the xp orb
var hero : CharacterBody2D

func _process(delta: float) -> void:
	if collected == true:
		# The movement may be more fancy than just moving towards the players
		position = position.move_toward(hero.position,speed)
		speed *= 1.03
		
		# Destroys the node when the player within the threshold (prevent floating calcs)
		
		if (position - hero.position).length() <= 0.1:
			xp_collected.emit()
			queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	# Checks if the area is the pick up radius
	if area.is_in_group("pick_up") and collected == false:
		collected = true
		hero = area.get_parent()
		
		# Connects to the player's hero
		# There were repeated connects error if the check wasn't there
		if xp_collected.is_connected(hero.on_xp_collected):
			return
		xp_collected.connect(hero.on_xp_collected)
