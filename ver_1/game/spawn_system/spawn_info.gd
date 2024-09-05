extends Resource

class_name SpawnInfo

## The time when the enemies spawning
@export var time_start:int

## The time when the enemies stop spawning
@export var time_end:int

## The scene containing the enemy
@export var enemy:Resource

## The amount of enemy spawned each time
@export var enemy_num:int

## The time delay between each spawn
@export var enemy_spawn_delay:int
var spawn_delay_counter : int = 0
