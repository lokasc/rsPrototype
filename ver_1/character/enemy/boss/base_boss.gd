class_name BaseBoss
extends BaseEnemy

signal changed_from_idle

@export_category("Multiplayer")
@export var main_state : BossAbility
#This variable syncs boss states via rpcs, you can turn this off if the boss is deterministic enough.
@export var use_rpc_sync : bool = false

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
	# dont allow clients to control their states if they're using use_rpc_sync
	if !multiplayer.is_server() && use_rpc_sync: return
	
	var new_state = states.get(state_new_name.to_lower())
	if !new_state:
		return
	check_change_from_idle(new_state)
	
	if current_state: current_state.exit()
	new_state.enter()
	
	# Changes state using rpcs. [Client]
	if use_rpc_sync: stc_state_change.rpc(state_new_name.to_lower())
	current_state = new_state

func state_change_from_any(state_new_name : String):
	# currently only bnb uses null, thus its safe from desync
	if state_new_name == "null":
		current_state.exit()
		current_state = null
		return
	
	if !multiplayer.is_server() && use_rpc_sync: return
	
	var new_state = states.get(state_new_name.to_lower())
	if !new_state:
		return
	
	check_change_from_idle(new_state)
	
	if current_state: current_state.exit()
	new_state.enter()
	if use_rpc_sync: stc_state_change.rpc(state_new_name.to_lower())
	current_state = new_state

# a conditional to check for changed_from_idle signal
func check_change_from_idle(new_state):
	if current_state.name == main_state.name:
		if new_state.name != main_state.name:
			changed_from_idle.emit()

func death():
	super()
	GameManager.Instance.is_boss_battle = false

#region multiplayer state sync

# this could be better by sending an int instead of a string.
@rpc("authority", "reliable", "call_remote")
func stc_state_change(state_new_name):
	# takes state-index and then changes state 
	var new_state = states.get(state_new_name.to_lower())
	if !new_state:
		return

	if current_state:
		current_state.exit()
	new_state.enter()
	current_state = new_state
	#print(current_state)

#if multiplayer.is_server():
		#print("SERVER Change! ",current_state, " : ", new_state)
	#else:
		#print("CLIENT Change! ",current_state, " : ", new_state)
#endregion
