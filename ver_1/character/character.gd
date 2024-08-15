class_name BaseCharacter
extends CharacterBody2D

@export_category("Basic Info")
@export var char_name : String
@export var char_id : int

var char_stats : Stats
var current_health : float

func _init():
	char_stats = Stats.new()
	pass
