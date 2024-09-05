class_name BaseAction
extends Node2D

var hero : BaseHero

@export var action_name : String = "" #ACTION NAME 
@export var desc : String
@export var level : int

@export var is_ascended : bool = false
var a_stats : Stats

# Visuals
var action_icon_path : String

func _init():
	a_stats = Stats.new()

# Override virtual func to change upgrade logic.
func _upgrade() -> void:
	if level == 5:
		is_ascended = true
	if level >= 5: 
		level = 5
		return # Upgraded a maximum of 5 times
	else:
		level += 1

func get_class_name() -> String:
	return get_script().get_global_name()
