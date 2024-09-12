class_name ArmourCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://assets/icons/armor_icon.png"
	amount_per_upgrade = 0.3
	display_upgrade_amount = "-"+ str(snapped(100-(100/(1+amount_per_upgrade)),1)) +"%"
	card_desc = "Reduces damage taken by a percentage"
	
	action_name = "Armour"

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.arm += amount_per_upgrade
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
	desc = "Armour\n" + "-"+ str(snapped(100-(100/(1+level*amount_per_upgrade)),1)) +"%"
