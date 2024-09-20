# meta-description: Skeleton for creating Items in the game
extends BaseItem

func _init() -> void:
	action_name = "Name"
	card_desc = "Description"
	action_icon_path = "res://assets/icons/aoe_icon.png"

# Connect any signals from the hero here.
func _enter_tree() -> void:
	#Example: hero.on_ability_used.connect()
	pass

# Write logic below here....

# Update is called by the main character
func _update(_delta:float) -> void:
	super(_delta)

func _upgrade() -> void:
	super()

# Override to apply stat changes.
func set_item_stats() -> void:
	super()
