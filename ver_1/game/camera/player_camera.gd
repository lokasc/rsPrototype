class_name PlayerCamera
extends Camera2D

## Controls the camera movement & effects. 
## Currently, it just follows the player.

@export var target : NodePath #Assign the node this camera will follow.

func _physics_process(_delta):
	if target:
		global_position = get_node(target).global_position
		
		# smooth follow player
		
		#position_smoothing_enabled = true
		#position_smoothing_speed = 2.5
