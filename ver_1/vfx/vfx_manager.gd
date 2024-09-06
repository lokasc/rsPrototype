class_name VFXManager
extends Node

@export_subgroup("Pop Ups")
var pop_up_scene = preload("res://ver_1/vfx/dmg_pop_up.tscn")
@onready var spawn_path = $PopUpContainer

# Object Pool
@export var initial_amount : int
var available_obj : Array[DmgPopUp] = []
var in_use_obj : Array[DmgPopUp] = []

func _enter_tree() -> void:
	GameManager.Instance.vfx = self

# Function called by characters taking damage.
func spawn_pop_up(num : float, gpos : Vector2):
	# TODO: Check if there is an existing id,
	
	# else get from the pool.
	var pop_up = get_object() 
	pop_up.set_up_data(1, num, gpos)

func get_object() -> DmgPopUp:
	# if there is an object in use.
	if available_obj.size() != 0:
		# removes from available and returns it.
		var obj = available_obj.pop_front() as DmgPopUp
		in_use_obj.append(obj)
		return obj
	# if there isnt any, create a new one.
	else:
		var copy = pop_up_scene.instantiate() as DmgPopUp
		copy.obj_finish.connect(release_obj)
		spawn_path.add_child(copy)
		in_use_obj.append(copy)
		return copy

# emitted by the signal.
func release_obj(obj : DmgPopUp):
	obj.clean_up()
	
	in_use_obj.erase(obj)
	available_obj.append(obj)

func _ready() -> void:
	# create 10 in the pool first.
	for x in initial_amount:
		var copy = pop_up_scene.instantiate() as DmgPopUp
		copy.obj_finish.connect(release_obj)
		spawn_path.add_child(copy)
		available_obj.append(copy)
