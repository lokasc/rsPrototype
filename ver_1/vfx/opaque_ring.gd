class_name BeatTexture
extends TextureRect

@export var starting_pos : Vector2
@export var is_lines : bool
@export var starting_color : Color = Color.WHITE
@export var ending_color : Color = Color.WHITE

var time_to_finish : float = 1.5
var max_size : float = 0
var min_size : float = 0


@onready var tween_container : Node = $TweenContainer

func _ready() -> void:
	if not is_lines:
		scale = min_size * Vector2.ONE
	else: position = starting_pos
	self_modulate = starting_color
	var tween = tween_container.create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(queue_free)
	if is_lines:
		tween.tween_property(self, "position", Vector2.ZERO, time_to_finish)
	else:
		tween.tween_property(self, "scale", max_size * Vector2.ONE, time_to_finish)
	tween.parallel().tween_property(self, "self_modulate", ending_color, time_to_finish)
