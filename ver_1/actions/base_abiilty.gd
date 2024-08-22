class_name BaseAbility
extends BaseAction

signal state_change
signal cooldown_finish
var is_on_cd : bool
var current_time : float

func enter():
	hero.ability_used.emit(self)

func exit():
	if !is_on_cd:
		start_cd()
	else:
		printerr("Used ability when on cooldown! check if ability is ready before changing state")

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass

func _init():
	super()
	cooldown_finish.connect(_on_cd_finish)
	is_on_cd = false
	current_time = 0

func _process(delta):
	if is_on_cd:
		current_time += delta
		if current_time >= a_stats.cd:
			cooldown_finish.emit()

# Starts the cooldown of the ability.
func start_cd():
	if !is_on_cd:
		is_on_cd = true

# FIXME: Refactor & change name
func use_ability():
	if !is_on_cd:
		is_on_cd = true

func _reset():
	is_on_cd = false
	current_time = 0
	pass

# Override virtual func to change what happens on cooldown finish
func _on_cd_finish():
	_reset()

func is_ready() -> bool:
	return !is_on_cd

# applies atk multiplier from hero to the attack.
func get_multiplied_atk() -> int:
	return hero.get_atk_mul() * a_stats.atk
