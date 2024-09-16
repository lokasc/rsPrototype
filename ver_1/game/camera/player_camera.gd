class_name PlayerCamera
extends Camera2D

## Controls the camera movement & effects. 
## Currently, it just follows the player.

@export var target : NodePath #Assign the node this camera will follow.
@export var hide_off_screen : bool
@onready var visibility_notifier = $Area2D/CollisionShape2D

func _physics_process(_delta:float):
	visibility_notifier.shape.size = get_viewport().get_visible_rect().size
	if target:
		global_position = get_node(target).global_position 

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent() is BaseEnemy:
		area.get_parent().show()


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.get_parent() is BaseEnemy and hide_off_screen:
		area.get_parent().hide()
