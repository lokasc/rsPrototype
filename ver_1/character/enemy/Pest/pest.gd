class_name Pest
extends BaseEnemy

@export var xp_worth = 1

@onready var sprite : Sprite2D = $Sprite2D
@onready var loot = get_tree().get_first_node_in_group("loot")
@onready var xp_orb = load("res://experience_orbs.tscn")

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
	
	if direction.x < 0:
		sprite.scale.x = 1
	elif direction.x > 0:
		sprite.scale.x = -1
	else:
		sprite.scale.x = -1
	
	
	move_and_slide()

func take_damage(dmg):
	super(dmg)
	if current_health <= 0:
		for i in range(xp_worth):
			var new_xp = xp_orb.instantiate()
			loot.call_deferred("add_child", new_xp)
			new_xp.position = position + Vector2(randi_range(-5,5),randi_range(-5,5))
		queue_free()


# TODO: FSM or STATE MACHINE for enemy
func _decide(target = null):
	if target == null:
		return
