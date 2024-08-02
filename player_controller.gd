class_name PlayerController
extends CharacterBody2D
## This script controls the player's movement and handles any other inputs
## with regards to the player


const SPEED = 400
const DECELERATION = 80

@export var health = 100
@onready var attack_box = $AttackBox

var stats_dictionary = { # placed in a dictionary for easy understanding, will be in a class later.
		"spd" : 10,
		"atk" : 10,
		"def" : 10,
		"dex" : 10,
		"vit" : 10,
}

func _ready():
	attack_box.monitoring = false

func _process(delta):
	if Input.is_action_just_pressed("attack"):
		print("HAI!")
		basic_attack()

func _physics_process(delta):
	# Create a vector input for reference
	var direction : Vector2 = Vector2(
		Input.get_axis("left", "right"), 
		Input.get_axis("down", "up")
	)
	
	# Movement
	if direction.x:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		
	if direction.y:
		velocity.y = direction.y * SPEED * -1
	else:
		velocity.y = move_toward(velocity.y, 0, DECELERATION)
	
	move_and_slide()

func on_hit(dmg):
	health -= dmg

func basic_attack():
	# start animation of attack.
	# for now, activate a hitbox in front of the player
	attack_box.monitoring = true
	await get_tree().create_timer(2).timeout
	attack_box.monitoring = false

func _on_attack_box_area_entered(area):
	# enemys have an hurtbox area2D node.
	var enemy = area.get_parent()
	if enemy is Enemy:
		print(enemy.name)
		enemy._on_hit(10)
	pass
