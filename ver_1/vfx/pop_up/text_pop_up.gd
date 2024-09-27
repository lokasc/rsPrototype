class_name TextPopUp
extends RichTextLabel

@export var DEFAULT_COLOR : Color = Color.WHITE
@export var DEFAULT_DURATION : float = 1.0

var started : bool

func _enter_tree() -> void:
	if get_parent() is BaseHero:
		get_parent().ability_used.connect(print_ability)

func _ready():
	$FadeTimer.timeout.connect(on_fade_timeout)
	reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !started: return
	
	global_position.y += -40 * delta
	
func print_ability(_abs):
	return
	set_pop(_abs.get_class_name(), get_parent().global_position)

func set_pop (_text : String, _gpos : Vector2, _color : Color = DEFAULT_COLOR, _duration : float = DEFAULT_DURATION):
	# Reset Text
	clear()
	visible = true
	global_position = _gpos
	
	push_color(_color)
	add_text(_text)
	started = true
	$FadeTimer.start(_duration)

func on_fade_timeout():
	reset()

func reset():
	visible = false
	clear()
