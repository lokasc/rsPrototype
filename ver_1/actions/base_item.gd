class_name BaseItem
extends BaseAction

func _enter_tree() -> void:
	a_stats = Stats.new()
	level = 1
	
	# Temporarily set description to the class name of the item.
	desc = get_class_name()
	card_desc = get_class_name()

func _update(_delta:float) -> void:
	pass
