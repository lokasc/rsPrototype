class_name MaxHPCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://assets/icons/maxhp_icon.png"
	amount_per_upgrade = 40
	card_desc = "Increases the maximum health"
	display_upgrade_amount = "+"+ str(amount_per_upgrade)
	
	action_name = "Max HP"

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.maxhp += int(amount_per_upgrade)
	#print("I upgraded my hp to %i", hero.char_stats.spd)
	desc = "Max HP\n" + "+" + str(level*amount_per_upgrade)
	set_hero_items_stats()
