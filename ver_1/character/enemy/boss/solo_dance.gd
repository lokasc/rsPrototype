class_name SoloDance
extends BossAbility

# The boss will target one player's box and randomly be at one of four sides
# The boss will shoot projectiles in a direction towards the player.

# Side is given by an int where:
# LEFT = 0, RIGHT = 1, TOP = 2, BOTTOM = 3

@export var is_biano : bool = false

@export var select_side_time : float = 2 # How long until you select a new side?
@export var change_side_time : float = 4 # How long in seconds until you change sides?
@export var visual_end_time : float = 2 # How long will the visual last?

@export var position_offset : float = 75 # How much do I move the spawn position back?

@export_group("Projectile settings")
@export var p_dmg : float = 10
@export var p_spd : float = 200
@export var projectile_scale : Vector2 = Vector2(1.1, 1.1)
@export var projectile_scene : PackedScene = preload("res://ver_1/character/enemy/boss/B&B/bnb_projectile.tscn")

@onready var side_visual = $SideWarningIndicator

var interval_changes_per_side_change = 2 # we change 2 times then we change the interval
var intervals : Array[float] = [1, 0.85, 0.7, 0.55]
var intervals_index : int = 0
var current_interval : float
var side_change_counts = 0
var current_proj_time = 0

var next_side = 0 # queue
var current_side = 0 # current we are on

var target : BaseHero
var rng = RandomNumberGenerator.new()
var right_spawn_y_pos : Array[float] = [30.5, 75, 119.5] # y positions for spawning on the right or left.
var bot_spawn_x_pos : Array[float] = [55, 100, 145] # these are x positions for spawning on the bottom or top.
var _color_index : int = 0


# the height of the box is 150
# the width of the box is 200 
# we can fit 4 projectiles
func _ready() -> void:
	super()
	current_interval = intervals[0]
	intervals_index = 0
	
	# ensure selecting is always before changing
	select_side_time = min(select_side_time, change_side_time-0.01)
	side_visual.visible = false

func enter() -> void:
	super()
	select_target()
	
	# basically what  on_side_change_timeout does
	increase_frequency()
	decide_side()
	current_side = next_side
	teleport_to_side()
	
	if !multiplayer.is_server(): return
	$SideChangeTimer.start(change_side_time)
	$SelectSideTimer.start(select_side_time)

func exit() -> void:
	super()
	$SideChangeTimer.stop()
	$SelectSideTimer.stop()
	side_visual.visible = false

func update(delta) -> void:
	if current_proj_time >= current_interval:
		shooting_pattern()
		current_proj_time = 0
	current_proj_time += delta

func physics_update(delta) -> void:
	super(delta)

func spawn_projectile(gpos : Vector2, direction : Vector2, color_index : int) -> void:
	if !multiplayer.is_server(): return
	var copy = projectile_scene.instantiate()
	
	# this projectiles specific damn thing
	copy.is_dance = true
	copy.color_index = color_index+1
	
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

	# if the next side is gay or sth. 
	while true:
		next_side = rng.randi_range(0, 3)
		if current_side != next_side:
			break

# increases frequencies based on no. of side changes.
func increase_frequency():
	if !multiplayer.is_server(): return
	
	# gradually increase the frequencies of tiles
	side_change_counts += 1
	if side_change_counts > interval_changes_per_side_change:
		side_change_counts = 0
		intervals_index += 1
		intervals_index = min(intervals_index, intervals.size() - 1)
		current_interval = intervals[intervals_index]

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

func get_side_pos(index) -> Vector2:
	var tp_pos = Vector2(0,0)
	match index:
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
	return tp_pos

# teleports to new side on timeout
func _on_side_change_timer_timeout() -> void:
	# set new side
	current_side = next_side
	increase_frequency()
	teleport_to_side()
	side_visual.visible = false
	$SelectSideTimer.start()

# selects a new side and displays arrow on timeout
func _on_select_side_timer_timeout() -> void:
	decide_side()
	activate_visual.rpc(next_side)
	
	#side_visual.look_at(get_side_pos(next_side))
	#side_visual.visible = true
	##print("c:",current_side, " vs ", "n:",next_side)

# makes visual look at new position
@rpc("authority", "call_local", "reliable")
func activate_visual(index):
	side_visual.look_at(get_side_pos(index))
	side_visual.visible = true
	$VisualEndTimer.start(visual_end_time)

func _on_visual_end_timer_timeout() -> void:
	side_visual.visible = false

# shoot projectiles based on the side you are on.
func shooting_pattern():
	var spawn_pos : Vector2 = Vector2.ZERO
	var spawn_direction : Vector2 
	
	match current_side:
		0: # spawn pos is on the left
			spawn_pos = Vector2(boss.global_position.x - position_offset,get_random_y_spawn() - 75)
			spawn_direction = Vector2.RIGHT
		1: # spawn pos is right
			spawn_pos = Vector2(boss.global_position.x + position_offset, get_random_y_spawn() - 75)
			spawn_direction = Vector2.LEFT
		2: # spawn pos is up 
			spawn_pos = Vector2(get_random_x_spawn() + 100, boss.global_position.y - position_offset)
			spawn_direction = Vector2.DOWN
			if !is_biano: spawn_pos.x = -spawn_pos.x
		3: # Spawn pos is down
			spawn_pos = Vector2(get_random_x_spawn() + 100, boss.global_position.y + position_offset)
			spawn_direction = Vector2.UP
			if !is_biano: spawn_pos.x = -spawn_pos.x
	
	spawn_projectile(spawn_pos, spawn_direction, _color_index)
	pass

# holy crap this is spaghetti code now, need to refactor ASAP. its hurting my brain
func get_random_y_spawn() -> float:
	var rng_index = rng.randi_range(0,right_spawn_y_pos.size() - 1)
	_color_index = rng_index
	return right_spawn_y_pos[rng_index]

func get_random_x_spawn() -> float:
	var rng_index = rng.randi_range(0,bot_spawn_x_pos.size() - 1)
	_color_index = rng_index
	return bot_spawn_x_pos[rng_index]
