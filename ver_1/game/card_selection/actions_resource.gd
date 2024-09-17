class_name ActionResource
extends Resource

@export var items : Array[PackedScene] = []
@export var stats : Array[Resource] = []

# Int works like this: items, then stats then atk, ab1, ab2, ult


func get_random_action() -> int:
	return randi_range(0, items.size()+ stats.size() -1)# + 4)


func is_action_valid(_index : int, _hero : BaseHero) -> int:
	# 1 = true
	# 0 = false
	# -1 = uve maxxed out everything.
	
	# Rules:
	# 1. if items/stats are full & the new item is an item/stat that 
	# the owner doesnt have -> return false 
	# 2. if item given is something that the hero has maxed out or ascended. 
	# 3. if maxxed out everything in ur hero list, return 2
	
	var is_stats_maxxed = true
	var is_items_maxxed = true
	
	# Check for if everything is maxxed out
	# TODO: Consider Abilities as well
	
	if _hero.stat_cards.size() == 4:
		for stat : BaseStatCard in _hero.stat_cards:
			if stat.level < 5: 
				is_stats_maxxed = false
				break
	else:
		is_stats_maxxed = false
	
	# we only have 2 items currently.
	if _hero.items.size() == 2:
		for item : BaseItem in _hero.items:
			if !item.is_ascended:
				is_items_maxxed = false
				break
	else:
		is_items_maxxed = false
	
	if is_stats_maxxed && is_items_maxxed:
		return -1
	
	# Filter out new actions when action slots are full
	if _hero.is_items_full() && is_item(_index) && !_hero.has_item(_index):
		return false
	
	if _hero.is_stats_full() && is_stat(_index) && !_hero.has_stat(_index):
		return false
	
	# Check if recieved index is already maxxed out or ascended.
	var action = _hero.get_action(get_new_class_script(_index))
	if action:
		if is_stat(_index) && action.level >= 5: return false
		# for abilities or items its ascension
		if action.is_ascended: return false
	
	# if after all these checks and it doesnt return, we good.
	return true


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

func is_item(index : int) -> bool:
	var script = get_new_class_script(index)
	if script is BaseItem:
		return true
	else:
		return false

func is_stat(index : int) -> bool:
	var script = get_new_class_script(index)
	if script is BaseStatCard:
		return true
	else:
		return false
