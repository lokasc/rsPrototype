class_name BaseAbility
extends BaseAction

signal state_change
signal cooldown_finish
signal ability_used # this signal is used to skip nam parsing.

enum Timing {NULL, EARLY, ON_BEAT, LATE}

var is_on_cd : bool
var current_time : float
var timing : int = Timing.NULL
var is_synced : bool = false

var initial_effect_scale := Vector2.ONE

var beat_count : int = 0 #used in basic attack

func _ready() -> void:
	BeatController.Instance.on_beat.connect(add_beat)

func enter() -> void:
	_reset()
	if hero == null: return
	hero.ability_used.emit(self)
	ability_used.emit()

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

func use_basic_attack() -> void:
	pass

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
	if !multiplayer.is_server(): return
	hero.gain_health(dmg_dealt * hero.char_stats.lifesteal)

func add_beat() -> void:
	if beat_count == 4:
		beat_count = 1
	else:
		beat_count += 1
