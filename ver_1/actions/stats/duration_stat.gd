class_name DurationCard
extends BaseStatCard

func _init() -> void:
	action_icon_path = "res://icon.svg"
	amount_per_upgrade = 0.2

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.dur += amount_per_upgrade
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
