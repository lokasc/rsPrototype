# meta-description: Skeleton for creating abilities, handles cooldowns & upgrading logic, shows all virtual functions. 
extends BaseAbility


# Initialize abilities
# WARNING: export variables wont be avaliable on init, use enter_tree
func _init():
	super()
	pass

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree():
	pass

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade():
	super()

# Override this for when an ability is used.
func use_ability():
	if is_on_cd: return
	super()

# Resets ability, lets players to use it again, override this to add functionality.
func _reset():
	super()

# Called automatically when ability cd finishes, override this to addd functionality when cd finishes
func _on_cd_finish():
	_reset()
