class_name DamageUp
extends BaseStatus

var dmg_multiplier : float
var duration : float
var duration_time : float

# Constructor, affects new() function for creating new copies of Freeze.
func _init(_dmg_multiplier : float, _duration : float) -> void:
	dmg_multiplier = _dmg_multiplier
	duration = _duration
	pass

func on_added() -> void:
	print(character.basic_attack.a_stats.atk)
	if character is BaseHero:
		character.basic_attack.a_stats.atk *= dmg_multiplier
	print(character.basic_attack.a_stats.atk)
	duration_time = 0
	pass

func update(delta) -> void:
	duration_time += delta
	if duration_time >= duration:
		holder.remove_status(self)
	pass

func on_removed() -> void:
	if character is BaseHero:
		character.basic_attack.a_stats.atk /= dmg_multiplier
	pass
