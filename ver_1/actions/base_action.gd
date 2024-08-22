class_name BaseAction
extends Node2D

var hero : BaseHero

@export var action_name : String = "" #ACTION NAME 
@export var desc : String
@export var level : int
var a_stats : Stats

# Visuals
var action_icon

func _init():
	a_stats = Stats.new()

# Override virtual func to change upgrade logic.
func _upgrade():
	level += 1
	pass

func get_class_name() -> String:
	return get_script().get_global_name()
