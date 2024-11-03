class_name IdleDance
extends BossAbility

# This is going to be called outside from the main state. 
# Players will not be able to damage this character.

var original_pos : Vector2

func enter() -> void:
	super()
	original_pos = boss.global_position
	boss.global_position = Vector2(10000, 10000)
	boss.visible = false

func exit() -> void:
	boss.global_position = original_pos
	boss.visible = true

func update(delta) -> void:
	pass

func physics_update(delta) -> void:
	super(delta)
