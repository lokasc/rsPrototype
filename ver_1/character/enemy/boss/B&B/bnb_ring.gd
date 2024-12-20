class_name BnBRing
extends BossAbility

@export var is_tgt : bool = false
@export var projectile_scene : PackedScene

# Projectiles are networked by instantiating under the
# nEtwork spwn path so that it dosnt mov dpndnt on th chaactr and is synchonizd.

@onready var spawn_path = get_parent().get_parent()

@export_category("Attack settings")
@export var num_per_attack : int = 8
@export var offset_from_center : float = 10
@export var frequency : float # How many attacks per second.

@export_subgroup("Pattern Settings")
@export var rest_time : float # How long u rest for after attacking.
@export var atk_time : float # How long ur attacking for until you get into rest

@export_category("Projectile settings")
@export var speed : float = 150
@export var dmg : float = 7.5

@export var spawn_time_array : Array[float] = [0.25, 0.375, 0.5, 1.25]

var attack_count : int
var current_atk_time : float = 0
var current_rest_time : float = 0
var is_resting : bool = false
var rand_color = 0


func enter() -> void:
	super()
	attack_count = 0
	current_time = 0
	rand_color = 0

# we reset temp values because firing timings will be off otherwise.
func exit() -> void:
	super() # starts cd here.
	attack_count = 0
	current_time = 0
	rand_color = 0
	is_resting = false
	current_atk_time = 0
	current_rest_time = 0

func update(_delta: float) -> void:
	super(_delta)
	if is_resting:
		current_rest_time += _delta
		
		# Change to atk state.
		if current_rest_time >= rest_time:
			attack_count = 0
			is_resting = false
			current_rest_time = 0
			current_time = 0
	else:
		# attacking for atk_time seconds.
		current_atk_time += _delta
		current_time += _delta
		
		if !(attack_count >= spawn_time_array.size()) && current_time >= spawn_time_array[attack_count]:
			spawn_pattern()
			#print(attack_count,": ",current_time)
			attack_count += 1
		
		# change to rest state.
		if current_atk_time >= atk_time:
			is_resting = true
			current_atk_time = 0

### shoots a ring around the piano
### On the first beat, shoots out a shotgun style
### pattern with faster bullet .

func shotgun_pattern() -> void:
	pass

func ring_pattern() -> void:
	var spawn_position : Vector2
	var rand_rotation : float
	var rotation_vec : Vector2
	# decide location and spawn.
	for x in num_per_attack:
		# decide random direction vector.
		rand_rotation = randf_range(0,360)
		rotation_vec = Vector2.UP.rotated(rand_rotation)
		spawn_position = global_position + offset_from_center * rotation_vec
		spawn_projectile(spawn_position)

	for x in GameManager.Instance.players:
		rotation_vec = global_position.direction_to(x.global_position)
		spawn_position = global_position + offset_from_center * rotation_vec
		spawn_projectile(spawn_position)
	rand_color += 1
	rand_color = rand_color%4

func spawn_pattern() -> void:
	if !multiplayer.is_server(): return
	
	ring_pattern()
	# SCOPE CREEP
	#if attack_count == 1:
		##shotgun_pattern()
		#ring_pattern()
	#else:
		#ring_pattern()

func spawn_projectile(gpos : Vector2) -> void:
	var copy = projectile_scene.instantiate()
	
	copy.dmg = dmg
	copy.spd = speed
	
	copy.initial_boss_atk = boss.initial_atk
	copy.boss_atk = boss.char_stats.atk
	
	copy.global_position = gpos
	copy.look_at(global_position)
	copy.rotate(deg_to_rad(180-90))

	#if rand_color == 0:
		#copy.modulate = Color(255,0,0)
	#if rand_color == 1:
		#copy.modulate = Color(0,255,0)
	#if rand_color == 2:
		#copy.modulate = Color(0,0,255)
	
	GameManager.Instance.net.spawnable_path.add_child(copy, true)
	# spawn in network node.
