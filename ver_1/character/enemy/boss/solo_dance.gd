class_name SoloDance
extends BossAbility

# The boss will target one player's box and randomly be at one of four sides
# The boss will shoot projectiles in a direction towards the player.

# Side is given by an int where:
# LEFT = 0, RIGHT = 1, TOP = 2, BOTTOM = 3

@export var is_biano : bool = false
@export var change_side_time : float = 4 # How long in seconds until you change sides?

@export_group("Projectile settings")
@export var p_dmg : float = 10
@export var p_spd : float = 200
@export var projectile_scale : Vector2
@export var projectile_scene : PackedScene = preload("res://ver_1/character/enemy/boss/B&B/bnb_projectile.tscn")

var current_interval : float = 0.75
var current_proj_time = 0


var current_side = 0
var prev_side = -1
var target : BaseHero
var rng = RandomNumberGenerator.new()
var right_spawn_y_pos : Array[float] = [18.75, 56.25, 93.75, 131.25]
var bot_spawn_x_pos : Array[float] = [25, 75, 125, 175] # these are x positions for spawning on the bottom or top.

# the height of the box is 150
# the width of the box is 200 
# we can fit 4 projectiles

func enter() -> void:
	super()
	select_target()
	decide_side()
	teleport_to_side()
	$SideChangeTimer.start(change_side_time)

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

func select_target():
	if is_biano: target = GameManager.Instance.get_player(1)
	else: 
		for x in GameManager.Instance.players:
			if x.id == 1: return
			target = x

func decide_side():
	if !multiplayer.is_server(): return
	while true:
		current_side = rng.randi_range(0, 3)
		if prev_side != current_side:
			prev_side = current_side
			break

# Teleport to a position based on the current side.
# todo: make it both ways.
func teleport_to_side():
	var tp_pos = Vector2(0,0)
	match current_side:
		0:
			if !is_biano: tp_pos = Vector2(-400, 0)
			else: tp_pos = Vector2.ZERO
		1:
			if !is_biano: tp_pos = Vector2.ZERO
			else: tp_pos = Vector2(400, 0)
		2:
			if !is_biano: tp_pos = Vector2(-200, -200)
			else: tp_pos = Vector2(200, -200)
		3:
			if !is_biano: tp_pos = Vector2(-200, 200)
			else: tp_pos = Vector2(200, 200)
	
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
		2: # spawn pos is up 
			spawn_pos = Vector2(get_random_x_spawn() + 100, boss.global_position.y)
			spawn_direction = Vector2.DOWN
			if !is_biano: spawn_pos.x = -spawn_pos.x
		3: # Spawn pos is down
			spawn_pos = Vector2(get_random_x_spawn() + 100, boss.global_position.y)
			spawn_direction = Vector2.UP
			if !is_biano: spawn_pos.x = -spawn_pos.x
	
	spawn_projectile(spawn_pos, spawn_direction)
	pass

func get_random_y_spawn() -> float:
	return right_spawn_y_pos[rng.randi_range(0,right_spawn_y_pos.size() - 1)]


func get_random_x_spawn() -> float:
	return bot_spawn_x_pos[rng.randi_range(0,bot_spawn_x_pos.size() - 1)]
