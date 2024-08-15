class_name EnemySpawner
extends Node2D


#Will change this in next patch
@export var game_manager : NetManager
@export var players : Array[BaseHero] = []

@export var spawn_path : Node 
@export var spawns: Array[Spawn_info] = []

var player 

@export var time = 0


func _start_timer():
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
					var enemy_spawn = new_enemy.instantiate() as BaseEnemy
					enemy_spawn.global_position = get_random_position()
					enemy_spawn.target = player
					spawn_path.add_child(enemy_spawn)
					counter += 1

func get_random_position(): #this code may change when in multiplayer
	var str = str(game_manager.connected_players[0])
	var parent = get_parent()
	player = parent.get_node(str)
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
