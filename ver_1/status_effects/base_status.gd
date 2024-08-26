class_name BaseStatus
extends Node

var character : BaseCharacter
var holder : StatusHolder

### Base class for all statuses.
func on_added():
	return null

func update(_delta:float):
	return null

func on_removed():
	return null
