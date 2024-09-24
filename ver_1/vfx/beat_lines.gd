class_name BeatLines
extends TextureRect

@export var starting_pos : Vector2
@export var starting_color : Color
@export var ending_color : Color

var time_to_finish : float
var max_size : float
var min_size : float


@onready var tween_container : Node = $TweenContainer

func _ready() -> void:
	position = starting_pos
	self_modulate = starting_color
	var tween = tween_container.create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(queue_free)
	tween.tween_property(self, "position", Vector2.ZERO,time_to_finish)
	tween.parallel().tween_property(self, "self_modulate", ending_color, time_to_finish)
