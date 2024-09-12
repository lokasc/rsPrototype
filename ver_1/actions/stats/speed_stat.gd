class_name SpeedCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://assets/icons/speed_icon.png"
	amount_per_upgrade = 10
	card_desc = "Increases movement speed"
	display_upgrade_amount = "+"+ str(snapped(amount_per_upgrade/150*100,1)) +"%" # 150 is base speed
	
	action_name = "Speed"

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.spd += int(amount_per_upgrade)
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
	desc = "Speed\n" + "+" + str(snapped(level*amount_per_upgrade/150*100,1)) +"%"
