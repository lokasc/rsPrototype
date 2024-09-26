class_name BeethovenIdle
extends BossAbility

var target : BaseHero


func enter() -> void:
	super()
	target = GameManager.Instance.players.pick_random()

func update(delta) -> void:
	check_if_player_in_range()
	pass

func physics_update(delta) -> void:
	# move towards the player
	boss.move_to_target(target)

func exit() -> void:
	pass


func check_if_player_in_range() -> void:
	if target.global_position.distance_to(global_position) <= 100:
		state_change.emit(self, "BeethovenSting")
	pass
