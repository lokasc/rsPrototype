extends MultiplayerSynchronizer
class_name PlayerInput


@export var mouse_pos : Vector2
@export var direction : Vector2
@export var attack : bool

# Change Input
var is_use_mouse_auto_attack : bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_multiplayer_authority():
		direction = Input.get_vector("left", "right", "up", "down")
		attack = Input.is_action_just_pressed("attack")
		mouse_pos = get_viewport().get_mouse_position()

