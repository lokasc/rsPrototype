class_name BaseAbility
extends BaseAction

signal state_change
signal cooldown_finish

enum Timing {NULL, EARLY, ON_BEAT, LATE}

var is_on_cd : bool
var current_time : float
var timing : int = Timing.NULL
var is_synced : bool = false

var initial_effect_scale := Vector2.ONE

func enter() -> void:
	hero.ability_used.emit(self)

func exit() -> void:
	if !is_on_cd:
		start_cd()
	else:
		printerr("Used ability when on cooldown! check if ability is ready before changing state")

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func _init() -> void:
	super()
	cooldown_finish.connect(_on_cd_finish)
	is_on_cd = false
	current_time = 0

func _process(delta) -> void:
	if is_on_cd:
		current_time += delta
		if current_time >= a_stats.cd:
			cooldown_finish.emit()

# Starts the cooldown of the ability.
func start_cd() -> void:
	if !is_on_cd:
		is_on_cd = true

# FIXME: Refactor & change name
func use_ability() -> void:
	if !is_on_cd:
		is_on_cd = true

func _reset() -> void:
	is_on_cd = false
	current_time = 0

# Override virtual func to change what happens on cooldown finish
func _on_cd_finish() -> void:
	_reset()

func is_ready() -> bool:
	#print(str(multiplayer.is_server()) + " ~ "+ str(current_time) + " " + str(!is_on_cd))
	return !is_on_cd

func set_ability_to_hero_stats() -> void:
	pass

# applies atk multiplier from hero to the attack.
func get_multiplied_atk() -> float:
	return int(hero.get_atk_mul() * a_stats.atk)

func lifesteal(dmg_dealt : float) -> void:
	hero.gain_health(dmg_dealt * hero.char_stats.hsg)
