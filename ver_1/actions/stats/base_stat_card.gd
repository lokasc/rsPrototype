class_name BaseStatCard
extends BaseAction

@export var amount_per_upgrade : float

func _init() -> void:
	# Temporarily set description to the class name of the item.
	desc = get_class_name()
	return

func _upgrade() -> void:
	super()
	for item : BaseItem in hero.items:
		item.set_item_stats()
