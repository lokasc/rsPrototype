class_name EnemySpawner
extends Node2D

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
	print(copy.global_position)
	spawn_path.add_child(copy, true)

func get_path_position(path : PackedScene) -> Vector2:
	var path_copy : Path2D = path.instantiate()
	var player_pos : Vector2 = GameManager.Instance.players.pick_random().global_position
	if path_copy.get_child(0) != PathFollow2D:
		printerr("Please insert a PathFollow2D node as a child of the Path2D scene")
	var path_follow : PathFollow2D = path_copy.get_child(0)
	path_path.add_child(path_copy, true)
	
	var rand_progress_ratio = randf_range(0,1)
	print(rand_progress_ratio)
	path_follow.progress_ratio = rand_progress_ratio
	return path_follow.global_position + player_pos

# Consider a different algorithm for selecting location.
func get_random_position() -> Vector2:
	var rect_pos = Vector2.ZERO
	rect_pos = GameManager.Instance.players.pick_random().global_position
	
	var vpr : Vector2 = get_viewport_rect().size * randf_range(0.7,1.1)
	
	var top_left : Vector2 = Vector2(rect_pos.x - vpr.x/2, rect_pos.y - vpr.y/2)
	var top_right : Vector2 = Vector2(rect_pos.x + vpr.x/2, rect_pos.y - vpr.y/2)
	var bottom_left : Vector2 = Vector2(rect_pos.x - vpr.x/2, rect_pos.y + vpr.y/2)
	var bottom_right : Vector2 = Vector2(rect_pos.x + vpr.x/2, rect_pos.y + vpr.y/2)
	
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
			spawn_pos1 = top_right
			spawn_pos2 = bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = bottom_left
	
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
	_boss.global_position = location
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

#func remove_children(node : Node) -> void:
	#for child in node.get_children():
		#child.queue_free()
