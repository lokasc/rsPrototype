class_name DuoDance
extends BossAbility

# The boss will target one player's box and randomly be at one of four sides
# The boss will shoot projectiles in a direction towards the player.

# Side is given by an int where:
# LEFT = 0, RIGHT = 1, TOPLEFT = 2, TOPRIGHT = 3, BOTTOMLEFT = 4, BOTTOMRIGHT = 5
signal changed_side(side)

@export var is_biano : bool = false
@export var change_side_time : float = 4 # How long in seconds until you change sides?

@export_group("Projectile settings")
@export var p_dmg : float = 10
@export var p_spd : float = 200
@export var projectile_scale : Vector2
@export var projectile_scene : PackedScene = preload("res://ver_1/character/enemy/boss/B&B/bnb_projectile.tscn")

var interval_changes_per_side_change = 3 # we change 3 times then we change the interval
var intervals : Array[float] = [0.75, 0.5, 0.25]
var intervals_index : int = 0
var current_interval : float
var side_change_counts = 0
var current_proj_time = 0

var ally_side = -1
var current_side = 0
var prev_side = -1
var rng = RandomNumberGenerator.new()
var right_spawn_y_pos : Array[float] = [18.75, 56.25, 93.75, 131.25]
var bot_spawn_x_pos : Array[float] = [9.375, 28.125, 46.875, 65.625] # these are x positions for spawning on the topleft/bottomleft

# the height of the box is 150
# the width of the box is 300
# we can fit 4 projectiles

func _ready() -> void:
	super()
	current_interval = intervals[0]
	intervals_index = 0

func enter() -> void:
	super()
	decide_side()
	teleport_to_side()
	$SideChangeTimer.start(change_side_time)
	if !is_biano && !boss.ally.duo_dance.changed_side.is_connected(on_biano_changed_side):
		boss.ally.duo_dance.changed_side.connect(on_biano_changed_side)

func exit() -> void:
	super()
	$SideChangeTimer.stop()

func update(delta) -> void:
	if current_proj_time >= current_interval:
		shooting_pattern()
		current_proj_time = 0
	current_proj_time += delta

func physics_update(delta) -> void:
	super(delta)

func spawn_projectile(gpos : Vector2, direction : Vector2) -> void:
	var copy = projectile_scene.instantiate()
	
	copy.dmg = p_dmg
	copy.spd = p_spd
	copy.tile_scale = projectile_scale
	
	copy.initial_boss_atk = boss.initial_atk
	copy.boss_atk = boss.char_stats.atk
	
	copy.global_position = gpos
	copy.rotate(direction.angle())
	copy.rotate(deg_to_rad(-90))
	
	#copy.look_at(target.global_position)
	#copy.rotate(deg_to_rad(270))
	
	GameManager.Instance.net.spawnable_path.call_deferred("add_child", copy, true)
	# spawn in network node.

func decide_side():
	if !multiplayer.is_server(): return
	
	# gradually increase the frequencies of tiles
	side_change_counts += 1
	if side_change_counts >= interval_changes_per_side_change:
		side_change_counts = 0
		intervals_index += 1
		intervals_index = min(intervals_index, intervals.size() - 1)
		current_interval = intervals[intervals_index]
		#print(current_interval)
	
	while true:
		current_side = rng.randi_range(0, 5)
		
		# Special note: do not let boss pick the same top/bottom side.
		if !is_biano:
			if (current_side == 2 || current_side == 4) && (ally_side == 2 || ally_side == 4): continue
			if (current_side == 3 || current_side == 5) && (ally_side == 3 || ally_side == 5): continue
		
		# dont pick the same side as ally and not the same as before
		if prev_side != current_side && current_side != ally_side:
			prev_side = current_side
			break
	if is_biano:
		# tell beethoven which side you are on.
		changed_side.emit(current_side)

# Teleport to a position based on the current side.
# todo: make it both ways.
func teleport_to_side():
	var tp_pos = Vector2(0,0)
	match current_side:
		0:
			tp_pos = Vector2(-300, 0)
		1:
			tp_pos = Vector2(300, 0)
		2:
			tp_pos = Vector2(-75, -200)
		3:
			tp_pos = Vector2(75, -200)
		4:
			tp_pos = Vector2(-75, 200)
		5:
			tp_pos = Vector2(75, 200)
	
	boss.global_position = tp_pos

func _on_side_change_timer_timeout() -> void:
	decide_side()
	teleport_to_side()

# shoot projectiles based on the side you are on.
func shooting_pattern():
	var spawn_pos : Vector2 = Vector2.ZERO
	var spawn_direction : Vector2
	
	match current_side:
		0: # spawn pos is on the left
			spawn_pos = Vector2(boss.global_position.x ,get_random_y_spawn() - 75)
			spawn_direction = Vector2.RIGHT
		1: # spawn pos is right
			spawn_pos = Vector2(boss.global_position.x, get_random_y_spawn() - 75)
			spawn_direction = Vector2.LEFT
		2: # spawn pos is top left
			spawn_pos = Vector2(-get_random_x_spawn(), boss.global_position.y)
			spawn_direction = Vector2.DOWN
		3: # Spawn pos is top right
			spawn_pos = Vector2(get_random_x_spawn(), boss.global_position.y)
			spawn_direction = Vector2.DOWN
		4: # Spawn pos is bot left
			spawn_pos = Vector2(-get_random_x_spawn(), boss.global_position.y)
			spawn_direction = Vector2.UP
		5: # Spawn pos is bot right
			spawn_pos = Vector2(get_random_x_spawn(), boss.global_position.y)
			spawn_direction = Vector2.UP
	
	spawn_projectile(spawn_pos, spawn_direction)
	pass

func get_random_y_spawn() -> float:
	return right_spawn_y_pos[rng.randi_range(0,right_spawn_y_pos.size() - 1)]

func get_random_x_spawn() -> float:
	return bot_spawn_x_pos[rng.randi_range(0,bot_spawn_x_pos.size() - 1)]

func on_biano_changed_side(side : int) -> void:
	ally_side = side
