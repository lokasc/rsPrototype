class_name ActionResource
extends Resource

@export var items : Array[PackedScene] = []
@export var stats : Array[Resource] = []

# Int works like this: items, then stats then atk, ab1, ab2, ult


func get_random_action() -> int:
	return randi_range(0, items.size()+ stats.size() -1)# + 4)

func get_action_resource(index : int) -> Resource:
	if index < items.size():
		return items[index]
	elif index < stats.size() + items.size():
		return stats[index-items.size()]
	else:
		return null

func get_new_class_script(index  : int) -> BaseAction:
	var resource = get_action_resource(index)
	if resource is PackedScene:
		return resource.instantiate().get_script().new()
	elif resource is GDScript:
		return resource.new()
	else:
		return null
