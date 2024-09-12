class_name CooldownCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://icon.svg"
	amount_per_upgrade = 0.1
	display_upgrade_amount = "-"+ str(amount_per_upgrade*100) +"%"
	card_desc = "Reduces Cooldowns for abilities and items"
	
	action_name = "Cooldown"

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.cd -= amount_per_upgrade
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
	desc = "Cooldown\n" + "-" + str(level*amount_per_upgrade*100) +"%"
