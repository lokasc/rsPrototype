class_name BeethovenIdle
extends BossAbility

var target : BaseHero

var current_delta 
var old_pos : Vector2
@export var path_follow : PathFollow2D
@export var path : Path2D


func enter() -> void:
	super()
	target = GameManager.Instance.players.pick_random()
	old_pos = boss.global_position
	current_delta = 0

func update(delta) -> void:
	check_if_player_in_range()
	pass

func physics_update(delta) -> void:
	# move towards the player
	super(delta)
	current_delta += delta * 100
	
	boss.global_position.y += sin(deg_to_rad(current_delta))
	
	boss.move_and_slide()

func exit() -> void:
	pass


func check_if_player_in_range() -> void:
	return
	if target.global_position.distance_to(global_position) <= 100:
		#state_change.emit(self, "BeethovenSting")
		state_change.emit(self, "BeethovenDashNSlash")
	pass
