class_name DamageUp
extends BaseStatus

var dmg_multiplier : float
var duration : float
var duration_time : float

# Constructor, affects new() function for creating new copies
func _init(_dmg_multiplier : float, _duration : float) -> void:
	dmg_multiplier = _dmg_multiplier
	duration = _duration
	pass

func on_added() -> void:
	if character is BaseHero:
		character.char_stats.atk_mul *= dmg_multiplier
	duration_time = 0
	pass

func update(delta:float) -> void:
	duration_time += delta
	if duration_time >= duration:
		holder.remove_status(self)
	pass

func on_removed() -> void:
	if character is BaseHero:
		character.char_stats.atk_mul /= dmg_multiplier
	pass
