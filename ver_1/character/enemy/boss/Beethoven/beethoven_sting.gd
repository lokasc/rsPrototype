class_name BeethovenSting
extends BossAbility

@export var charge_speed : float = 10
@export var initial_dmg : float = 20

var target : BaseHero
var target_position : Vector2
var direction
var speed
# the bee waits for a bit before dashing towards you

@onready var waiting_timer : Timer = $WaitingTimer
var is_waiting : bool

var current_duration : float = 0
var max_duration : float

# TODO: Proability of picking a character depends on the distance to the bee
func choose_player():
	var closest_player : BaseHero
	var closest_pos = 1000000
	
	for x in GameManager.Instance.players:
		if closest_pos > global_position.distance_to(x.global_position):
			closest_player = x
	
	return closest_player


func enter() -> void:
	super()
	$Area2D.monitoring = false
	target = choose_player()
	waiting_timer.stop()
	waiting_timer.start(1.5)
	current_duration = 0
	is_waiting = true

func update(delta) -> void:
	if is_waiting: return
	boss.global_position = boss.global_position.move_toward(target_position, charge_speed)
	if boss.global_position == target_position:
		state_change.emit(self, "BeethovenSting")
		return

func physics_update(delta) -> void:
	if is_waiting: return

func exit() -> void:
	$Area2D.monitoring = false
	current_duration = 0
	pass

func _on_waiting_timer_timeout() -> void:
	target_position = target.global_position
	
	$Area2D.look_at(target_position)
	$Area2D.monitoring = true
	is_waiting = false


func _on_area_2d_area_entered(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
		
	if !character: return 	# do not execute on non-characters or nulls
	character.take_damage(boss.char_stats.atk/boss.initial_atk * initial_dmg)
