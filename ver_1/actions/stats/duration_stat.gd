class_name DurationCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://assets/icons/duration_icon.png"
	amount_per_upgrade = 0.2
	card_desc = "Increases the duration of abilities and item effects"
	display_upgrade_amount = "+"+ str(amount_per_upgrade*100) +"%"
	
	action_name = "Duration"
	

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.dur += amount_per_upgrade
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
	desc = "Duration\n" + "+" + str(level*amount_per_upgrade*100) +"%"
	set_hero_items_stats()
