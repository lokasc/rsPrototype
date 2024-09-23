class_name BeatTexture
extends TextureRect

var time_to_max_size : float
var max_size : float
var min_size : float
var speed : float
var starting_color : Color
var ending_color : Color

@onready var tween_container : Node = $TweenContainer

func _ready() -> void:
	scale = min_size * Vector2.ONE
	self_modulate = starting_color
	var tween = tween_container.create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(queue_free)
	tween.tween_property(self, "scale", max_size * Vector2.ONE, time_to_max_size)
	tween.parallel().tween_property(self, "self_modulate", ending_color, time_to_max_size)
