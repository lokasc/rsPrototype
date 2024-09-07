class_name BnBRain
extends BossAbility

# In this attack, piano tiles drop from the air and hit you.

@export var is_tgt : bool = false
@export var projectile_scene : PackedScene

@onready var spawn_path = get_parent().get_parent()

@export_category("Attack settings")
@export var height : float # How far you drop.
@export var num_per_attack : int
@export var offset_from_center : float

# Max distance a tile will spawn (starting from offset)
@export var range : float
@export var frequency : float # How many attacks per second.

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


###
# 1. Spawn pattern, ring like (hades, turn around)
# 2. Choose like 5-6 random directions, and spawn them at the same time.

func spawn_pattern() -> void:
	if !multiplayer.is_server(): return
	
	var position : Vector2
	var rand_rotation : float
	var rand_position : int
	var rotation_vec : Vector2
	# decide location and spawn.
	for x in num_per_attack:
		# decide random direction vector.
		rand_rotation = randf_range(0,360)
		rotation_vec = Vector2.UP.rotated(rand_rotation)
		
		rand_position = randi_range(0, range)
		
		position = global_position + ((offset_from_center + rand_position) * rotation_vec)
		position.y -= height
		spawn_projectile(position)

func spawn_projectile(gpos : Vector2) -> void:
	var copy = projectile_scene.instantiate()
	
	copy.is_rain = true
	
	copy.height = height
	copy.dmg = dmg
	copy.spd = speed
	
	copy.initial_boss_atk = boss.initial_atk
	copy.boss_atk = boss.char_stats.atk
	
	copy.global_position = gpos
	
	# spawn in network node for sync
	spawn_path.add_child(copy, true)
