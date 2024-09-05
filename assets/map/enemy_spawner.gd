class_name EnemySpawner
extends Node2D

#Will change this in next patch
@export var spawn_path : Node 
@export var spawns: SpawnsResource
var player : BaseHero
var time : int = 0

func _enter_tree() -> void:
	GameManager.Instance.spawner = self

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
	for info in enemy_spawns:
		if (time >= info.time_start and time <= info.time_end) or info.time_end == -1:
			if info.spawn_delay_counter < info.enemy_spawn_delay:
				info.spawn_delay_counter += 1
			else:
				info.spawn_delay_counter = 0
				var new_enemy: Resource = info.enemy
				var counter : int = 0
				while  counter < info.enemy_num:
					instantiate_enemy(new_enemy)
					counter += 1

func instantiate_enemy(new_enemy)-> void:
	var copy : BaseEnemy = new_enemy.instantiate() as BaseEnemy
	copy.global_position = get_random_position()
	spawn_path.add_child(copy, true)

# Consider a different algorithm for selecting location.
func get_random_position():
	var combined_pos = Vector2.ZERO
	for x in GameManager.Instance.players:
		combined_pos += x.global_position
	
	var vpr : Vector2 = get_viewport_rect().size * randf_range(0.7,1.1)
	
	var top_left : Vector2 = Vector2(combined_pos.x - vpr.x/2, combined_pos.y - vpr.y/2)
	var top_right : Vector2 = Vector2(combined_pos.x + vpr.x/2, combined_pos.y - vpr.y/2)
	var bottom_left : Vector2 = Vector2(combined_pos.x - vpr.x/2, combined_pos.y + vpr.y/2)
	var bottom_right : Vector2 = Vector2(combined_pos.x + vpr.x/2, combined_pos.y + vpr.y/2)
	
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
	copy.global_position = location
	spawn_path.add_child(copy, true)
