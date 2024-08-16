class_name BaseAction
extends Node2D

var action_owner : BaseHero

@export var action_name : String #ACTION NAME 
@export var desc : String
@export var level : int
var a_stats : Stats


func _init():
	a_stats = Stats.new()

# Override virtual func to change upgrade logic.
func _upgrade():
	level += 1
	pass
