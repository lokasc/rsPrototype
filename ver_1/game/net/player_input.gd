extends MultiplayerSynchronizer
class_name PlayerInput

const CAMERA_OFFSET = Vector2(-640,-360)
var player : BaseHero

@export var is_on_beat : bool
@export var mouse_pos : Vector2
@export var direction : Vector2
@export var attack : bool
@export var ability_1 : bool:
	set(value):
		ability_1 = value
@export var ability_2 : bool:
	set(value):
		print(value)
		ability_2 = value
@export_subgroup("Conditions")
@export var canMove : bool = true

# Change Input
var is_use_mouse_auto_attack : bool = true

func _enter_tree() -> void:
	root_path = NodePath("..")
	player = get_parent()

func get_mouse_position() -> Vector2:
	if player.is_personal_camera:
		# Offset is required to get the actual mouse position
		return player.input.mouse_pos + player.camera.global_position + CAMERA_OFFSET
	else:
		return mouse_pos

@rpc("call_local", "reliable")
func ctc_abs2():
	ability_2 = true

@rpc("call_local")
func ctc_abs1():
	ability_1 = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_multiplayer_authority():
		if canMove:
			direction = Input.get_vector("left", "right", "up", "down")
		else:
			direction = Vector2.ZERO
		attack = Input.is_action_just_pressed("attack")
		
		
		if Input.is_action_just_pressed("ability_2"):
			ctc_abs2.rpc()
		if Input.is_action_just_pressed("ability_1"):
			ctc_abs1.rpc()
		
		mouse_pos = get_viewport().get_mouse_position()
		
		# Give client leniancy, let them check instead.
		if ability_1 || ability_2:
			is_on_beat = GameManager.Instance.bc.is_on_beat()
		
		# Give players leniancy with regard to their cooldowns.
