class_name PlayerCamera
extends Camera2D

## Controls the camera movement & effects. 
## Currently, it just follows the player.

@export var target : BaseHero #Assign the node this camera will follow.
@export var hide_off_screen : bool

@export_subgroup("Optimization")
@export var update_frequency : float = 3
var current_update_time : float = 0

@onready var visibility_notifier = $Area2D/CollisionShape2D

func _process(delta:float) -> void:
	if !GameManager.Instance.is_game_started(): return
	current_update_time += delta
	
	if current_update_time >= update_frequency:
		#change_area_shape()
		current_update_time = 0

func _ready():
	# connect signals if we have a target.
	if target:
		$Area2D.area_entered.connect(_on_area_2d_area_entered)
		$Area2D.area_exited.connect(_on_area_2d_area_exited)
		visibility_notifier.shape.size = Vector2(1280,720)

# May have to do the same to experience orbs
func _on_area_2d_area_entered(area: Area2D) -> void:
	if !target: return
	var enemy = area.get_parent()
	if (enemy is BaseEnemy || enemy is XpOrbs) && !enemy.visible:
		#if multiplayer.is_server(): print("Ive shown " + str(enemy))
		enemy.show()

func _on_area_2d_area_exited(area: Area2D) -> void:
	if !target: return
	var enemy = area.get_parent()
	if (enemy is BaseEnemy || enemy is XpOrbs) && hide_off_screen && enemy.visible:
		#if multiplayer.is_server(): print("Ive Hidden " + str(enemy))
		enemy.hide()

func change_area_shape() -> void:
	var r_width : float # right side calculated width
	var l_width : float # left side calculated width
	var t_height : float # top side calculated height
	var b_height : float # bottom side calculated height
	
	# width and height of the collider
	var height : float
	var width : float
	
	# player's positions
	var rect_pos_p1 := Vector2.ZERO
	var rect_pos_p2 := Vector2.ZERO
	
	var visibility_notifier_position : Vector2
	var vpr := Vector2(1280,720)
	
	rect_pos_p1 = GameManager.Instance.players[0].global_position
	# hot fix for singleplayer
	if GameManager.Instance.net.MAX_CLIENTS == 1:
		rect_pos_p2 = GameManager.Instance.players[0].global_position
	else:
		rect_pos_p2 = GameManager.Instance.players[1].global_position
		if get_parent() == GameManager.Instance.players[1]:
			visibility_notifier.set_deferred("disabled", true) # disables one of the second collider
	
	# Setting Viewport rectangles of each player
	var top_left_p1 : Vector2 = Vector2(rect_pos_p1.x - vpr.x/2, rect_pos_p1.y - vpr.y/2)
	var bottom_right_p1 : Vector2 = Vector2(rect_pos_p1.x + vpr.x/2, rect_pos_p1.y + vpr.y/2)
	var top_left_p2 : Vector2 = Vector2(rect_pos_p2.x - vpr.x/2, rect_pos_p2.y - vpr.y/2)
	var bottom_right_p2 : Vector2 = Vector2(rect_pos_p2.x + vpr.x/2, rect_pos_p2.y + vpr.y/2)
	
	# Calculates the position in between the two players
	visibility_notifier_position = lerp(rect_pos_p2, rect_pos_p1, 0.5)
	
	## The follow comparison takes the furthest cordinate on a side, and calculates the larger width/height
	
	#Left, comparing player positions to calculate the width
	if top_left_p1.x - visibility_notifier_position.x <= top_left_p2.x - visibility_notifier_position.x:
		l_width = abs((top_left_p1.x - visibility_notifier_position.x) * 2)
	else:
		l_width = abs((top_left_p2.x - visibility_notifier_position.x) * 2)
	
	#Right, comparing player positions to calculate the width
	if bottom_right_p1.x - visibility_notifier_position.x >= bottom_right_p2.x - visibility_notifier_position.x:
		r_width = abs((bottom_right_p1.x - visibility_notifier_position.x) * 2)
	else:
		r_width = abs((bottom_right_p2.x - visibility_notifier_position.x) * 2)
	
	# Compares left and right calculated widths, selects the largest one
	width = l_width if l_width >= r_width else r_width
	
	#Top, comparing player positions to calculate the height
	if top_left_p1.y - visibility_notifier_position.y <= top_left_p2.y - visibility_notifier_position.y:
		t_height = abs((top_left_p1.y - visibility_notifier_position.y) * 2)
	else:
		t_height = abs((top_left_p2.y - visibility_notifier_position.y) * 2)
	
	#Bottom, comparing player positions to calculate the height
	if bottom_right_p1.y - visibility_notifier_position.y >= bottom_right_p2.y - visibility_notifier_position.y:
		b_height = abs((bottom_right_p1.y - visibility_notifier_position.y) * 2)
	else:
		b_height = abs((bottom_right_p2.y - visibility_notifier_position.y) * 2)
	
	# Compares top and bottom calculated height, selects the largest one
	height = t_height if t_height >= b_height else b_height
	
	# Makes sure no enemies disappear within the camera
	if width < 1280: width = 1280
	if height < 720: height = 720
	
	# Sets the position and size
	visibility_notifier.shape.size = Vector2(width, height)
	visibility_notifier.global_position = visibility_notifier_position

func camera_shake(intensity : float) -> void: 
	pass
