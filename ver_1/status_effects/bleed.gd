class_name Bleed
extends BaseStatus

var bleed_dmg : int # Dmg dealt per rate
var rate : float # time taken for one instance of dmg dealt
var duration : float # Total duration of effect

var duration_time : float
var current_time : float
var visual_time : float

var bleed_visual_time : float = 0.2# Time for the bleed red color to be displayed

# Constructor, affects new() function for creating new copies of Bleed.
func _init(_bleed_dmg : int, _duration : float, _rate : float):
	bleed_dmg = _bleed_dmg
	duration = _duration
	rate = _rate
	pass

func on_added():
	current_time = bleed_visual_time
	duration_time = 0
	visual_time = 0

func update(_delta):
	current_time += _delta
	duration_time += _delta
	visual_time += _delta
	
	if visual_time >= bleed_visual_time:
		character.modulate = Color.WHITE
		visual_time = 0
	
	if current_time >= rate:
		current_time = 0
		bleed()
	
	# remove me
	if duration_time >= duration:
		holder.remove_status(self)

func on_removed():
	character.modulate = Color.WHITE

func bleed():
	character.take_damage(bleed_dmg)
	character.modulate = Color.RED
	visual_time = 0
