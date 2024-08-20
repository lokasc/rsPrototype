class_name Bleed
extends BaseStatus

var bleed_dmg
var current_time
var rate

var duration_time
var duration




func _init(_bleed_dmg, _duration, _rate):
	bleed_dmg = _bleed_dmg
	duration = _duration
	rate = _rate
	pass

func on_added():
	current_time = 0
	duration_time = 0

func update(_delta):
	current_time += _delta
	duration_time += _delta
	
	if current_time >= rate:
		current_time = 0
		bleed()
	
	# remove me
	if duration_time >= duration:
		holder.remove_status(self)

func bleed():
	character.take_damage(bleed_dmg)
