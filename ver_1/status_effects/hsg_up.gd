class_name HealShieldGainUp
extends BaseStatus

var hsg_multiplier : float
var duration : float
var duration_time : float

# Constructor, affects new() function for creating new copies
func _init(_hsg_multiplier : float, _duration : float) -> void:
	hsg_multiplier = _hsg_multiplier
	duration = _duration
	pass

func on_added() -> void:
	if character is BaseHero:
		character.char_stats.hsg *= hsg_multiplier
	duration_time = 0
	pass

func update(delta) -> void:
	duration_time += delta
	if duration_time >= duration:
		holder.remove_status(self)
	pass

func on_removed() -> void:
	if character is BaseHero:
		character.char_stats.hsg /= hsg_multiplier
	pass
