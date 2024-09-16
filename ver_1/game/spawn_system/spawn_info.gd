class_name SpawnInfo
extends Resource

enum Spawn_Type {
	Screen, ## Spawns around the screen, default
	Path, ## Spawns on the path, requires path resources
	None ## Does not spawn
}

## The time when the enemies spawning
@export var time_start:int

## The time when the enemies stop spawning
@export var time_end:int

## The scene containing the enemy
@export var enemy : Resource

## The amount of enemy spawned each time
@export var enemy_num:int

## The time delay between each spawn
@export var enemy_spawn_delay:int
var spawn_delay_counter : int = 0

## This determines how the enemies spawn
@export var spawn_type : Spawn_Type

## If spawn type is path, drop a scene with a path as the root node here
@export var path : Resource
