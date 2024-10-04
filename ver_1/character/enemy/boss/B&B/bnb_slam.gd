class_name BnBSlam
extends BossAbility

@export var is_tgt : bool = false
@export var slam_range : float = 5
@onready var slam_area : Area2D = $SlamArea


var s_current_time : float = 0
var active_duration : float = 0.1
# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func _ready() -> void:
	slam_area.get_child(0).shape.radius = slam_range

func enter() -> void:
	super()
	slam_area.monitoring = true
	slam_area.get_child(0).debug_color = Color("ff8bffcf")

func update(delta) -> void:
	s_current_time += delta
	if s_current_time >= active_duration:
		on_slam_animation_finish()

func exit() -> void:
	slam_area.monitoring = false
	slam_area.get_child(0).debug_color = Color("aafbfa40")
	s_current_time = 0

func on_slam_animation_finish() -> void:
	if is_tgt: change_state_phase_one()

func change_state_phase_one() -> void:
	#printerr(boss.phase)
	if boss.phase == 1:
		state_change.emit(self, "BnBRing")
	elif boss.phase == 2:
		state_change.emit(self, "BnBRain")
	elif boss.phase == 3:
		boss.state_change_from_any("null")


func _on_slam_area_hit(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
		
	if !character: return 	# do not execute on non-characters or nulls
	character.add_status("Knockback", [slam_range-(character.global_position.distance_to(global_position)), global_position, 12])
