class_name DamageCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://assets/icons/dmg_icon.png"
	amount_per_upgrade = 15
	display_upgrade_amount = "+"+ str(amount_per_upgrade)
	card_desc = "Increases damage dealt by attacks, abilities and items"
	
	action_name = "Damage"

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.atk += int(amount_per_upgrade)
	#print("I upgraded my hp to %i", hero.char_stats.atk)
	desc = "Damage\n" + "+"+ str(level*amount_per_upgrade)
	set_hero_items_stats()
