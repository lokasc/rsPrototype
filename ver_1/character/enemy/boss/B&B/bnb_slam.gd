class_name BnBSlam
extends BossAbility

@export var is_tgt : bool = false

# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func enter() -> void:
	super()
	print("SLAM!")

func update(delta) -> void:
	on_slam_animation_finish()

func on_slam_animation_finish() -> void:
	if is_tgt: change_state_phase_one()

func change_state_phase_one() -> void:
	printerr(boss.phase)
	if boss.phase == 1:
		state_change.emit(self, "BnBRing")
	elif boss.phase == 2:
		state_change.emit(self, "BnBRain")
