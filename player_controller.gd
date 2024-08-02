class_name PlayerController
extends CharacterBody2D
## This script controls the player's movement and handles any other inputs
## with regards to the player

const SPEED = 400
const DECELERATION = 80

@export var health = 100
@onready var attack_box = $AttackBox
@onready var collision_box = $AttackBox/CollisionShape2D

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
		print("Attack!")
		basic_attack()

func _physics_process(delta):
	# Create a vector input for reference
	var direction : Vector2 = Input.get_vector("left", "right", "up", "down")
	
	# Movement
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO,DECELERATION)
	
	move_and_slide()

func on_hit(dmg):
	health -= dmg

func basic_attack():
	# start animation of attack.
	# for now, activate a hitbox in front of the player
	attack_box.monitoring = true
	collision_box.debug_color = Color("dd488d6b")
	await get_tree().create_timer(2).timeout
	attack_box.monitoring = false
	collision_box.debug_color = Color("0099b36b")

func _on_attack_box_area_entered(area):
	# enemys have an hurtbox area2D node.
	var enemy = area.get_parent()
	if enemy is Enemy:
		print(enemy.name)
		enemy._on_hit(10)
	pass
