class_name BaseCharacter
extends CharacterBody2D

@export_category("Basic Info")
@export var char_name : String
@export var char_id : int


var status_holder : StatusHolder

var char_stats : Stats
var current_health : float
var current_shield : float

func _init():
	char_stats = Stats.new()

func _ready() -> void:
	# Weird warning call, ignorable.
	status_holder = get_node("StatusHolder")
	if !status_holder:
		var scene : Resource = load("res://ver_1/status_effects/status_holder.tscn")
		if !scene:
			printerr("Warning, no status holder or correct scene path")
		else:
			var copy = scene.instantiate()
			copy.character = self
			status_holder = copy
			add_child(copy)
	else:
		status_holder.character = self

func add_status(effect_name, args):
	status_holder.add_status(effect_name, args)

# Override this in enemy and hero to change logic
func take_damage(_dmg):
	pass
