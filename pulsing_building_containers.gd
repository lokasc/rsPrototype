extends Node2D

var building_array : Array[Node]
@onready var spectrum_helper = $"../AudioSpectrumHelper"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	building_array = get_children()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for building in building_array:
		building.scale = (1+spectrum_helper.lerped_spectrum[6]) * Vector2.ONE
