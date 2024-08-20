class_name StatusHolder
extends Node

# save computation by caching, in node order?
var statuses : Array[BaseStatus]
var character : BaseCharacter

# Bug: a status effect is applied twice (perhaps a collision layer issue)
func add_status(status : BaseStatus):
	status.character = character
	status.holder = self
	
	status.on_added()
	statuses.append(status)
	add_child(status)

func _process(_delta):
	for status : BaseStatus in statuses:
		status.update(_delta)

func remove_status(status : BaseStatus):
	status.on_removed()
	statuses.erase(status)
	remove_child(status)
	status.queue_free()
