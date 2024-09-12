class_name PickUpRadiusCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://assets/icons/pickup_icon.png"
	amount_per_upgrade = 0.5

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.pick += amount_per_upgrade
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
