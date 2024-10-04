class_name Knockback
extends BaseStatus

const SPEED = 1

var kb_distance : float # the distance at which the character is knocked back
var kb_speed_multiplier : float # multiplier of speed of the knockback finishing, default is 1
var player_pos : Vector2 # the position of the hero that applied the knockback

var original_pos : Vector2
var new_pos : Vector2
var direction : Vector2

# Constructor, affects new() function for creating new copies.
func _init(_kb_distance : float, _player_pos : Vector2, _kb_speed_multiplier : float = 1):
	kb_distance = _kb_distance
	player_pos = _player_pos
	kb_speed_multiplier = _kb_speed_multiplier
	pass

func on_added():
	if character is BaseHero:
		character.input.canMove = false
	original_pos = character.position
	direction = player_pos.direction_to(original_pos)
	new_pos = original_pos + direction * kb_distance

func update(_delta:float):
	character.position = character.position.move_toward(new_pos, SPEED * kb_speed_multiplier)
	
	# remove me
	if character.position == new_pos:
		holder.remove_status(self)

func physics_update(_delta:float):
	return
	character.velocity = direction * SPEED * kb_speed_multiplier
	# remove me
	if character.position.x >= abs(new_pos.x) && character.position.y*-1 > new_pos.y * -1 :
		holder.remove_status(self)

func on_removed():
	if character is BaseHero:
		character.input.canMove = true
