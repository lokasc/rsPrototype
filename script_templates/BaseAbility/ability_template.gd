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

# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func enter():
	pass

func exit():
	super() # starts cd here.


func update(_delta: float):
	super(_delta)
	pass

func physics_update(_delta: float):
	super(_delta)
	pass

# This func is used for auto_attack, dont change this.
func use_ability():
	if is_on_cd: return
	super()

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade():
	super()

# Called automatically when ability cd finishes, override this to addd functionality when cd finishes
func _on_cd_finish():
	_reset()

# Resets ability, lets players to use it again, override this to add functionality.
func _reset():
	super()
