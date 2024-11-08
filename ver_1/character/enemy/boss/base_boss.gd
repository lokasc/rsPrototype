class_name BaseBoss
extends BaseEnemy

signal changed_from_idle

@export_category("Attacks")
@export var main_state : BossAbility

# STATEMACHINE
var states : Dictionary = {}
var current_state : BaseAbility
var initial_state : BaseAbility
# Bosses have state-machines

var initial_atk : float

func _ready() -> void:
	super()
	_init_states()
	initial_atk = char_stats.atk
	GameManager.Instance.is_boss_battle = true


func _process(_delta: float) -> void:
	super(_delta)
	if current_state:
		current_state.update(_delta)
func _physics_process(_delta: float) -> void:
	if current_state:
		current_state.physics_update(_delta)

func _init_states():
	if !initial_state:
		initial_state = main_state

	current_state = initial_state
	current_state.enter()

func _parse_abilities(x : BossAbility):
	if x:
		x.boss = self
		states[x.name.to_lower()] = x
		x.state_change.connect(on_state_change)

func on_state_change(state_old, state_new_name:String):
	var new_state = states.get(state_new_name.to_lower())
	if !new_state:
		return
	
	check_change_from_idle(new_state)
	
	if current_state:
		current_state.exit()
	
	new_state.enter()
	
	#print("State Change! ",current_state, " : ", new_state)
	current_state = new_state

func state_change_from_any(state_new_name : String):
	if state_new_name == "null":
		current_state.exit()
		current_state = null
		return
	
	
	var new_state = states.get(state_new_name.to_lower())
	if !new_state:
		return
	
	check_change_from_idle(new_state)
	
	if current_state:
		current_state.exit()
	
	new_state.enter()
	current_state = new_state

# a conditional to check for changed_from_idle signal
func check_change_from_idle(new_state):
	if current_state.name == main_state.name:
		if new_state.name != main_state.name:
			changed_from_idle.emit()

func death():
	super()
	GameManager.Instance.is_boss_battle = false
