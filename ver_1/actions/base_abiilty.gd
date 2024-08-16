class_name BaseAbility
extends BaseAction

# Cooldown logic

signal state_change
signal cooldown_finish
var is_on_cd : bool
var current_time : float

var hero : BaseHero

func enter():
	pass

func exit():
	if !is_on_cd:
		is_on_cd = true
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

# starts cd if not on cd.
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
