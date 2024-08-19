class_name EnemySpawner
extends Node2D


#Will change this in next patch
@export var spawn_path : Node 
@export var spawns: Array[Spawn_info] = []
var player 

@export var time = 0

func _enter_tree() -> void:
	GameManager.Instance.spawner = self

func _ready() -> void:
	# add all enemies in spawner to spawn list.
	for spawn : Spawn_info in spawns:
		$MultiplayerSpawner.add_spawnable_scene(spawn.enemy.resource_path)

func _start_timer():
	if !multiplayer.is_server(): return
	$Timer.start()

func _on_timer_timeout():
	time += 1
	var enemy_spawns = spawns
	for info in enemy_spawns:
		if (time >= info.time_start and time <= info.time_end) or info.time_end == -1:
			if info.spawn_delay_counter < info.enemy_spawn_delay:
				info.spawn_delay_counter += 1
			else:
				info.spawn_delay_counter = 0
				var new_enemy = info.enemy
				var counter = 0
				while  counter < info.enemy_num:
					instantiate_enemy(new_enemy)
					counter += 1

func instantiate_enemy(new_enemy):
	var copy = new_enemy.instantiate() as BaseEnemy
	copy.global_position = get_random_position()
	spawn_path.add_child(copy, true)
	pass

# Consider a different algorithm for selecting location.
func get_random_position():
	player = GameManager.Instance.players[0]
	
	var vpr = get_viewport_rect().size * randf_range(1.1,1.4)
	
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	
	var pos_side = ["up","down","right","left"].pick_random()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
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
	
	var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)
	var y_spawn = randf_range(spawn_pos1.y,spawn_pos2.y)
	return Vector2(x_spawn,y_spawn)
