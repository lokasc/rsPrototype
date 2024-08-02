class_name LevelController
extends Sprite2D

## Controls aspects of a level, including but not limited to:
## Timer
## Spawning enemies
## Respawning player
## Managing difficulting throughout the level
## NB:  A "level" is a run of the game.  

@export var enemy_scene : PackedScene
@export var player : NodePath
var count = 0

func _process(delta):
	if count <= 3:
		count += 1
		add_enemy()

func add_enemy():
	# spawns an enemy in a range away from the player.
	
	pass
	
