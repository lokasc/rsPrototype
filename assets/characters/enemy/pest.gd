class_name Pest
extends Enemy

@onready var target = get_tree().get_first_node_in_group("player") #will be changed in multiplayer
var SPEED = 200

func _init():
	health = 100

func _physics_process(_delta):
	# direction the pest needs to go towards:
	var direction = global_position.direction_to(target.global_position)
	var distance = global_position.distance_to(target.global_position)
	
	#sqrt(
			#pow(target.global_position.x - global_position.x,2) + 
			#pow(target.global_position.y - global_position.y,2)
	#)
	
	#print(distance)
	
	if distance < 15:
		velocity = Vector2.ZERO
	else:
		velocity = direction * SPEED
	move_and_slide()


func _decide(target = null):
	if target == null:
		return
	
	# move towards player
	global_position = global_position.move_toward(target.global_position, SPEED)

