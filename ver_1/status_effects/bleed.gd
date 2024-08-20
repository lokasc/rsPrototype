class_name Bleed
extends BaseStatus

var bleed_dmg # Dmg dealt per rate
var rate # time taken for one instance of dmg dealt
var duration # Total duration of effect

var duration_time
var current_time

# Constructor, affects new() function for creating new copies of Bleed.
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
