extends Control

## The speed at which the bar interpolates from one value to another, the smaller the number, the faster it is
@export var tween_speed : float = 0.05

## Determines how tall the visualizer goes
@export var height : int = 60

## The maximum frequency visualized
@export var max_freq : float = 10000

# The minimum the visualiser can go, I think?
var min_db : int = 65

# Gets the spectrum analyzer from the audio bus
@onready var spectrum : AudioEffectInstance = AudioServer.get_bus_effect_instance(1,0)

@onready var vu_count : int = $RectangleBase/Right/Bottom.get_child_count()
# Gets an array of the bars
@onready var bottom_right_array : Array = $RectangleBase/Right/Bottom.get_children()

@onready var tween_container : Node = $TweenContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var prev_hz = 0
	for i in range(1, vu_count+1):
		# Calculating variables
		var hz = i * max_freq/vu_count
		var f = spectrum.get_magnitude_for_frequency_range(prev_hz,hz)
		var energy = clamp((min_db + linear_to_db(f.length()))/min_db, 0, 1)
		var height_actual = energy * height
		
		prev_hz = hz
		
		var bottom_right_rect = bottom_right_array[i - 1] 
		
		var tween = tween_container.create_tween()
		# interpolate the size of the bars, changing the y size but keeping the x size the same
		tween.tween_property(bottom_right_rect, "size", Vector2(bottom_right_rect.size.x, height_actual), tween_speed)
