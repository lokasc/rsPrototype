class_name ActionResource
extends Resource

@export var items : Array[Resource] = []
@export var stats : Array[Resource] = []

# Int works like this: items, then stats then atk, ab1, ab2, ult


# TODO: Serialize and Deserialize here.
func get_random_action() -> int:
	return randi_range(0, items.size()+ stats.size() + 4 - 1)

func get_action_resource(index : int) -> Resource:
	if index < items.size():
		return items[index]
	elif index < stats.size() + items.size():
		return stats[index-items.size()]
	else:
		return null
