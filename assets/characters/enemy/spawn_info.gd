extends Resource

class_name Spawn_info

##The time when the enemies spawning
@export var time_start:int

##The time when the enemies stop spawning
@export var time_end:int

##The scene containing the enemy
@export var enemy:Resource

##The amount of enemy spawned each time
@export var enemy_num:int
@export var enemy_spawn_delay:int

var spawn_delay_counter = 0
