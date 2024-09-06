class_name DmgPopUp
extends Node2D

### This class handles a dmg pop up visual.

# tells the pool to return this object to the pool.
signal obj_finish(this_obj)

# object Id of the one taking damage.
var owner_id : int 

# Temp storage.
var current_dmg : float = 0

# Container for pop up, is used for animating the label.
var container : Node2D

# starts the pop up
var is_started : bool = false

# timer for animations.
var current_time : float = 0
var max_time : float = 1

func set_up_data(id : int, number : float, gpos : Vector2):
	container = get_child(0)
	(container.get_child(0) as Label).text = str(number)
	
	owner_id = id
	global_position = gpos
	
	container.modulate.a = 1
	container.scale = Vector2(2,2)
	
	visible = true
	is_started = true
	set_process(true)

func _process(delta: float) -> void:
	if !is_started: return
	
	# Animate based on time
	container.global_position.y -= delta * 100
	container.modulate.a = max(0, container.modulate.a-delta)
	container.scale -= Vector2(delta, delta)
	
	current_time += delta
	if current_time >= max_time:
		is_started = false
		obj_finish.emit(self)

# Reset temp data
func clean_up():
	visible = false
	current_dmg = 0
	owner_id = 0
	current_time = 0
	set_process(false)
