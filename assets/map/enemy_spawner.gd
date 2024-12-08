class_name EnemySpawner
extends Node2D

@export var spawning_min_range : float = 1
@export var spawning_max_range : float = 1
## distance between two player's global position that when greater, would change the spawn type from enveloping viewport to random individual viewports
@export var switch_spawn_type_distance : int = 1280

#Will change this in next patch
@export var spawn_path : Node 
@export var path_path : Node
@export var spawns: SpawnsResource


var player : BaseHero
var time : int = 0

func _enter_tree() -> void:
	GameManager.Instance.spawner = self
	GameManager.Instance.end_game.connect(on_end_game)

func _ready() -> void:
	# add all enemies in spawner to spawn list.
	for spawn : SpawnInfo in spawns.array:
		$MultiplayerSpawner.add_spawnable_scene(spawn.enemy.resource_path)

func _start_timer():
	if !multiplayer.is_server(): return
	$Timer.start()

func _on_timer_timeout():
	time += 1
	var enemy_spawns : Array[SpawnInfo] = spawns.array
	var new_enemy: Resource
	var counter : int
	for info in enemy_spawns:
		if (time >= info.time_start and time <= info.time_end) or info.time_end == -1:
			#remove_children(path_path)
			if info.spawn_type == SpawnInfo.Spawn_Type.None: 
				continue
			if info.spawn_delay_counter < info.enemy_spawn_delay:
				info.spawn_delay_counter += 1
			else:
				info.spawn_delay_counter = 0
				new_enemy = info.enemy
				counter = 0
				while  counter < info.enemy_num:
					if info.spawn_type == SpawnInfo.Spawn_Type.Screen:
						instantiate_enemy_from_screen(new_enemy)
					elif info.spawn_type == SpawnInfo.Spawn_Type.Path:
						instantiate_enemy_from_path(new_enemy, info.path)
					counter += 1

func instantiate_enemy_from_screen(new_enemy)-> void:
	var copy : BaseEnemy = new_enemy.instantiate() as BaseEnemy
	if copy is BaseBoss:
		
		# Boss spawn location
		spawn_boss(copy, Vector2(0,0))
		return
	copy.global_position = get_random_position()
	spawn_path.add_child(copy, true)

func instantiate_enemy_from_path(new_enemy:Resource, path:Resource) -> void:
	if path == null: return
	var copy : BaseEnemy = new_enemy.instantiate() as BaseEnemy
	copy.global_position = get_path_position(path)
	spawn_path.add_child(copy, true)

func get_path_position(path : PackedScene) -> Vector2:
	var path_copy : Path2D = path.instantiate()
	var player_pos : Vector2 = GameManager.Instance.players.pick_random().global_position
	if path_copy.get_child(0) != PathFollow2D:
		printerr("Please insert a PathFollow2D node as a child of the Path2D scene")
	var path_follow : PathFollow2D = path_copy.get_child(0)
	path_path.add_child(path_copy, true)
	
	var rand_progress_ratio = randf_range(0,1)
	path_follow.progress_ratio = rand_progress_ratio
	return path_follow.global_position + player_pos

# Consider a different algorithm for selecting location.
func get_random_position() -> Vector2:
	var rect_pos_p1 := Vector2.ZERO
	var rect_pos_p2 := Vector2.ZERO
	
	# Spawning Rectangle corners
	var top_left := Vector2.ZERO
	var top_right := Vector2.ZERO
	var bottom_left := Vector2.ZERO
	var bottom_right := Vector2.ZERO
	
	var vpr : Vector2 = Vector2(1280,720) * randf_range(spawning_min_range,spawning_max_range)
	
	rect_pos_p1 = GameManager.Instance.players[0].global_position
	# hot fix for singleplayer
	if GameManager.Instance.net.MAX_CLIENTS == 1:
		rect_pos_p2 = GameManager.Instance.players[0].global_position
	else:
		rect_pos_p2 = GameManager.Instance.players[1].global_position
	
	# Setting Viewport rectangles of each player
	var top_left_p1 : Vector2 = Vector2(rect_pos_p1.x - vpr.x/2, rect_pos_p1.y - vpr.y/2)
	var bottom_right_p1 : Vector2 = Vector2(rect_pos_p1.x + vpr.x/2, rect_pos_p1.y + vpr.y/2)
	var top_left_p2 : Vector2 = Vector2(rect_pos_p2.x - vpr.x/2, rect_pos_p2.y - vpr.y/2)
	var bottom_right_p2 : Vector2 = Vector2(rect_pos_p2.x + vpr.x/2, rect_pos_p2.y + vpr.y/2)
	
	# Setting the Spawning Rectangle size
	# Two ways of spawning, 1 is a big rectangle enveloping both viewports, 2 is choosing between individual viewports
	if rect_pos_p2.distance_to(rect_pos_p1) < switch_spawn_type_distance:
		top_left.x = top_left_p1.x if top_left_p1.x < top_left_p2.x else top_left_p2.x
		top_left.y = top_left_p1.y if top_left_p1.y < top_left_p2.y else top_left_p2.y
		bottom_right.x = bottom_right_p1.x if bottom_right_p1.x > bottom_right_p2.x else bottom_right_p2.x
		bottom_right.y = bottom_right_p1.y if bottom_right_p1.y > bottom_right_p2.y else bottom_right_p2.y
		top_right.x = bottom_right.x
		top_right.y = top_left.y
		bottom_left.x = top_left.x
		bottom_left.y = bottom_right.y
	else:
		var rect_pos_rand = [rect_pos_p1,rect_pos_p2].pick_random()
		top_left = Vector2(rect_pos_rand.x - vpr.x/2, rect_pos_rand.y - vpr.y/2)
		top_right = Vector2(rect_pos_rand.x + vpr.x/2, rect_pos_rand.y - vpr.y/2)
		bottom_left = Vector2(rect_pos_rand.x - vpr.x/2, rect_pos_rand.y + vpr.y/2)
		bottom_right = Vector2(rect_pos_rand.x + vpr.x/2, rect_pos_rand.y + vpr.y/2)
	
	var pos_side : String = ["up","down","right","left"].pick_random()
	var spawn_pos1 : Vector2 = Vector2.ZERO
	var spawn_pos2 : Vector2 = Vector2.ZERO
	
	match pos_side:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = top_right
		"down":
			spawn_pos1 = bottom_left
			spawn_pos2 = bottom_right
		"right":
			spawn_pos1 = bottom_right
			spawn_pos2 = top_right
		"left":
			spawn_pos1 = bottom_left
			spawn_pos2 = top_left
	
	var x_spawn : float = randf_range(spawn_pos1.x, spawn_pos2.x)
	var y_spawn : float = randf_range(spawn_pos1.y,spawn_pos2.y)
	return Vector2(x_spawn,y_spawn)

# used for debugging & custom spawn.

# make sure it is in autospawn list.
func custom_spawn(file_name, location):
	var new_enemy = load(file_name)
	var copy : BaseEnemy = new_enemy.instantiate() as BaseEnemy
	
	if copy is BaseBoss:
		spawn_boss(copy, location)
		return

	copy.global_position = location
	spawn_path.add_child(copy, true)

func spawn_boss(_boss : BaseBoss, location : Vector2):
	# kill all children first.
	if multiplayer.is_server():
		remove_all_children()
	
	_boss.global_position = location
	#spawn_path.call_deferred("add_child", _boss, true)
	spawn_path.add_child(_boss, true)
	GameManager.Instance.ui.stc_set_boss_ui.rpc(_boss.char_id)


# TODO: Random, Unique ID not implemented.
# can be called on client-sides
func get_enemy_from_id(id : int) -> BaseEnemy:
	for x in spawn_path.get_children():
		if x is not BaseEnemy: continue
		if !x.char_id: continue
		if x.char_id == id:
			return x 
	return null

func on_end_game():
	$Timer.stop()
	for enemy : BaseEnemy in spawn_path.get_children():
		enemy.on_end_game()

# removes every child that is not a boss
func remove_all_children() -> void:
	for x : Node in spawn_path.get_children():
		if x is BaseBoss: continue
		x.queue_free()
