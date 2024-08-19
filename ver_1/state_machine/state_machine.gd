class_name StateMachine

var initial_state : BaseState

var current_state : BaseState
var states : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#for child in get_children():
		#if child is BaseState:
			#states[child.name.to_lower()] = child
			#child.state_change.connect(on_state_change)
	#if initial_state:
		#initial_state.enter()
		#current_state = initial_state

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func on_state_change(state_old, state_new_name):
	if state_old != current_state:
		return
	
	var new_state = states.get(state_new_name.to_lower())
	if !new_state:
		return
	
	if current_state:
		current_state.exit()
	
	new_state.enter()
	current_state = new_state
