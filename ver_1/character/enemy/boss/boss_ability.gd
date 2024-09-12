class_name BossAbility
extends BaseAbility

var boss : BaseBoss

func enter() -> void:
	return

func lifesteal(_dmg_dealt : float) -> void:
	return


func _init() -> void:
	super()

func _process(_delta) -> void:
	return

# Starts the cooldown of the ability.
func start_cd() -> void:
	return
# FIXME: Refactor & change name
func use_ability() -> void:
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
