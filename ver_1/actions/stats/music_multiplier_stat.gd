class_name MusicMultiplierCard
extends BaseStatCard

func _init() -> void:
	super()
	action_icon_path = "res://icon.svg"
	amount_per_upgrade = 0.1
	card_desc = "Increases the effect gained from beat sync"
	display_upgrade_amount = "+"+ str(amount_per_upgrade*100) +"%"
	
	action_name = "Music Multiplier"

func _upgrade():
	super()
	if level >= 5: return # do not increase health after level 5
	hero.char_stats.mus += amount_per_upgrade
	#print("I upgraded my hp to %i", hero.char_stats.maxhp)
	desc = "Music Multiplier\n" + "+" + str(level*amount_per_upgrade*100) +"%"
