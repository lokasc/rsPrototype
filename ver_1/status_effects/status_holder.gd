class_name StatusHolder
extends Node

# save computation by caching, in node order?
var statuses : Array[BaseStatus]
var character : BaseCharacter

func add_status(effect_name, arg):
	if !multiplayer.is_server(): return
	tell_clients_add_status.rpc(effect_name, arg)

func _process(_delta):
	for status : BaseStatus in statuses:
		status.update(_delta)

func remove_status(status : BaseStatus):
	status.on_removed()
	statuses.erase(status)
	remove_child(status)
	status.queue_free()

@rpc("call_local")
func tell_clients_add_status(effect_name, arg):
	match effect_name:
		"Bleed":
			var copy = Bleed.new(arg[0], arg[1], arg[2])
			copy.character = character
			copy.holder = self
			statuses.append(copy)
			add_child(copy, true)
			copy.on_added()
		"Freeze":
			var copy = Freeze.new(arg[0], arg[1], arg[2])
			copy.character = character
			copy.holder = self
			statuses.append(copy)
			add_child(copy, true)
			copy.on_added()
		"DamageUp":
			var copy = DamageUp.new(arg[0], arg[1])
			copy.character = character
			copy.holder = self
			statuses.append(copy)
			add_child(copy, true)
			copy.on_added()
		"HealShieldGainUp":
			var copy = HealShieldGainUp.new(arg[0], arg[1])
			copy.character = character
			copy.holder = self
			statuses.append(copy)
			add_child(copy, true)
			copy.on_added()
