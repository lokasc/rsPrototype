class_name Pest
extends BaseEnemy

@onready var sprite : Sprite2D = $Sprite2D

func _init():
	super()
	pass

func _enter_tree():
	super()
	pass
	

func _physics_process(_delta):
	# direction the pest needs to go towards:
	var direction = global_position.direction_to(target.global_position)
	var distance = global_position.distance_to(target.global_position)
	
	if distance < 15:
		velocity = Vector2.ZERO
	else:
		velocity = direction * char_stats.spd
	
	if direction.x <0:
		sprite.scale.x = 1
	elif direction.x >0:
		sprite.scale.x = -1
	else:
		sprite.scale.x = -1
			
	
	move_and_slide()

func take_damage(dmg):
	super(dmg)
	if current_health <= 0:
		queue_free()


# TODO: FSM or STATE MACHINE for enemy
func _decide(target = null):
	if target == null:
		return