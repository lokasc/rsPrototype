class_name BnBRing
extends BossAbility

@export var is_tgt : bool = false
@export var projectile_scene : PackedScene

# Projectiles are networked by instantiating under the
# nEtwork spwn path so that it dosnt mov dpndnt on th chaactr and is synchonizd.

@onready var spawn_path = get_parent().get_parent()

@export_category("Attack settings")
@export var num_per_attack : int
@export var offset_from_center : float
@export var frequency : float # How many attacks per second.

@export_subgroup("Pattern Settings")
@export var rest_time : float # How long u rest for after attacking.
@export var atk_time : float # How long ur attacking for until you get into rest

var current_atk_time : float = 0
var current_rest_time : float = rest_time

@export_category("Projectile settings")
@export var speed : float
@export var dmg : float



func enter() -> void:
	super()
	current_time = 1/frequency
	
func exit() -> void:
	super() # starts cd here.

func update(_delta: float) -> void:
	super(_delta)
	current_time += _delta
	if current_time >= 1/frequency:
		spawn_pattern()
		current_time = 0

func shooting_state(_delta) -> void:
	# shooting state.
	current_time += _delta
	current_atk_time += _delta
	
	if current_time >= 1/frequency:
		spawn_pattern()
		current_time = 0

func rest_state(_delta) -> void:
	current_rest_time += _delta

###
# 1. Spawn pattern, ring like (hades, turn around)
# 2. Choose like 5-6 random directions, and spawn them at the same time.

func spawn_pattern() -> void:
	if !multiplayer.is_server(): return
	
	var position : Vector2
	var rand_rotation : float
	var rotation_vec : Vector2
	# decide location and spawn.
	for x in num_per_attack:
		# decide random direction vector.
		rand_rotation = randf_range(0,360)
		rotation_vec = Vector2.UP.rotated(rand_rotation)
		position = global_position + offset_from_center * rotation_vec
		spawn_projectile(position)

func spawn_projectile(gpos : Vector2) -> void:
	var copy = projectile_scene.instantiate()
	
	copy.dmg = dmg
	copy.spd = speed
	
	copy.initial_boss_atk = boss.initial_atk
	copy.boss_atk = boss.char_stats.atk
	
	copy.global_position = gpos
	copy.look_at(global_position)
	copy.rotate(deg_to_rad(180-90))
	
	spawn_path.add_child(copy, true)
	# spawn in network node.
	
