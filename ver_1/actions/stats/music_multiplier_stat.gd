class_name MusicMultiplierCard
extends BaseStatCard

func _init() -> void:
	action_icon_path = "res://assets/icons/heart-plus.png"
	amount_per_upgrade = 0.1

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.mus += int(amount_per_upgrade)
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
