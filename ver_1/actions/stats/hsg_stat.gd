class_name HealShieldGainCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://assets/icons/hsg_icon.png"
	amount_per_upgrade = 0.02
	card_desc = "Increases the amount of shield and healing gained"
	display_upgrade_amount = "+"+ str(amount_per_upgrade*100) +"%"
	
	action_name = "Heal & Shield Gain"

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.hsg += amount_per_upgrade
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
	desc = "Heal & Shield Gain\n" + "+" + str(level*amount_per_upgrade*100) +"%"
	set_hero_items_stats()
