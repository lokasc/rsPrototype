class_name BossAbility
extends BaseAbility

var boss : BaseBoss

func enter() -> void:
	return

func lifesteal(dmg_dealt : float) -> void:
	return


func _init() -> void:
	super()

func _process(delta) -> void:
	return

# Starts the cooldown of the ability.
func start_cd() -> void:
	return
# FIXME: Refactor & change name
func use_basic_attack() -> void:
	return

func _reset() -> void:
	return

# Override virtual func to change what happens on cooldown finish
func _on_cd_finish() -> void:
	return

func is_ready() -> bool:
	return 0

func set_ability_to_hero_stats() -> void:
	pass

# applies atk multiplier from hero to the attack.
func get_multiplied_atk() -> float:
	return 0

func choose_player() -> BaseHero:
	var closest_player : BaseHero
	var closest_pos = 1000000
	
	for x in GameManager.Instance.players:
		if closest_pos > global_position.distance_to(x.global_position):
			closest_player = x
	
	return closest_player
