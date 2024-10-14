class_name Knockback
extends BaseStatus

const SPEED = 1

var kb_distance : float # the distance at which the character is knocked back
var kb_speed_multiplier : float # multiplier of speed of the knockback finishing, default is 1
var player_pos : Vector2 # the position of the hero that applied the knockback

var original_pos : Vector2
var new_pos : Vector2
var direction : Vector2

var time_to_move : float = 0
var total_kb_time : float 

# Constructor, affects new() function for creating new copies.
func _init(_kb_distance : float, _player_pos : Vector2, _kb_speed_multiplier : float = 1):
	kb_distance = _kb_distance
	player_pos = _player_pos
	kb_speed_multiplier = _kb_speed_multiplier
	time_to_move = 0
	pass

func on_added():
	if character is BaseHero:
		character.input.canMove = false
	if character is BaseEnemy:
		character.can_move = false
	
	original_pos = character.position
	direction = player_pos.direction_to(original_pos)
	new_pos = original_pos + direction * kb_distance
	
	total_kb_time = kb_distance/(SPEED * kb_speed_multiplier * Engine.physics_ticks_per_second)

func update(_delta:float):
	return

func physics_update(_delta:float):
	# Apply and move character backwards, until a set amount of time. 
	character.velocity = direction * SPEED * kb_speed_multiplier * Engine.physics_ticks_per_second
	
	time_to_move += _delta
	if time_to_move >= total_kb_time:
		holder.remove_status(self)

func on_removed():
	if character is BaseHero:
		character.input.canMove = true
	if character is BaseEnemy:
		character.can_move = true
