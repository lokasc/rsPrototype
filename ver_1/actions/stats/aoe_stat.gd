class_name AOECard
extends BaseStatCard


func _init() -> void:
	super()
	action_icon_path = "res://assets/icons/aoe_icon.png"
	amount_per_upgrade = 0.1
	display_upgrade_amount = "+"+ str(amount_per_upgrade*100) +"%"
	card_desc = "Increases Area size abilities and items"
	action_name = "Area"

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.aoe += amount_per_upgrade
	desc = "Area\n" + "+"+ str(level*amount_per_upgrade*100) +"%"
	set_hero_items_stats()
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
