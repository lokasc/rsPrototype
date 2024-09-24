class_name BeatVisualizer
extends Control

signal ability_input_pressed()

@export var time_to_finish : float
@export var note_path : Control

@export_group("Rings")
@export var max_size : float
@export var min_size : float
## the starting color of the moving ring
@export var starting_color : Color

## the ending color of the moving ring
@export var ending_color : Color

## the color of the particle effects
@export var particle_color : Color

## the color of the outer trans ring when NOT on beat
@export var transparent_ring_color : Color

## the color of the outer trans ring when IT IS on beat
@export var beating_color : Color

@export_group("Lines")
@export var is_lines : bool
@export var text_pop_up : TextPopUp 

@export var starting_position : Vector2

## Grace time for when it is great
@export var great_grace_time : float

## Grace time for when it is perfect
@export var perfect_grace_time : float

## Color of the transparent line when trying to beat sync
@export_subgroup("Colors")

## the color of the outer trans line when NOT on beat
@export var transparent_line_color : Color

## Color of the text when the beat sync is perfect
@export var perfect_color : Color

## Color of the text when the beat sync is great
@export var great_color : Color

## Color of the text when the beat sync is good
@export var good_color : Color

## Color of the text when the beat sync is bad
@export var bad_color : Color

var time_til_next_beat: float
var text_color : Color # Color of the text pop up
var new_note : Node
var note_count : int
var opaque_ring : Resource = preload("res://ver_1/vfx/opaque_ring.tscn")
var beat_line : Resource = preload("res://ver_1/vfx/beat_lines.tscn")
var opaque_line : Resource = preload("res://ver_1/vfx/opaque_ring_lines.tscn")

@onready var trans_ring : TextureRect = $TransparentRing
@onready var particles : GPUParticles2D = $GPUParticles2D
@onready var effect_timer : Timer = $EffectTimer

@onready var bc : BeatController = GameManager.Instance.bc
@onready var hero : BaseHero

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_lines:
		$TransparentRing.scale = max_size * Vector2.ONE
	# Connecting on beat signals to effects
		bc.on_beat.connect(show_pressed_effect)
		bc.on_beat.connect(spawn_ring.bind(time_to_finish, min_size, max_size))
		trans_ring.self_modulate = transparent_ring_color
	if is_lines:
		hide()
		ability_input_pressed.connect(show_pressed_effect)
		#bc.on_beat.connect(spawn_beatline.bind(time_to_finish, starting_position))
		trans_ring.self_modulate = transparent_line_color
	particles.process_material.color = particle_color
	trans_ring.self_modulate = transparent_ring_color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_lines: return
	if GameManager.Instance.local_player == null: return
	
	hero = GameManager.Instance.local_player
	if hero.input.ability_1 and visible:
		ability_input_pressed.emit()
		if text_pop_up == null: return
		check_accuracy(bc.get_time_til_next_beat())


func spawn_beatline(_time_to_finish : float, _starting_pos : Vector2) -> void:
	new_note = beat_line.instantiate()
	new_note.starting_pos = _starting_pos
	new_note.scale = trans_ring.scale
	new_note.time_to_finish = _time_to_finish
	note_path.add_child(new_note)

func spawn_note(_time_to_finish : float, _starting_pos : Vector2) -> void:
	new_note = opaque_line.instantiate()
	new_note.scale = trans_ring.scale
	new_note.starting_pos = _starting_pos
	new_note.time_to_finish = _time_to_finish
	note_path.add_child(new_note)
	note_count += 1

func spawn_ring(_time_to_finish : float, _min_size : float, _max_size) -> void:
	new_note = opaque_ring.instantiate()
	new_note.starting_color = starting_color
	new_note.ending_color = ending_color
	new_note.min_size = _min_size
	new_note.max_size = _max_size
	new_note.time_to_finish = _time_to_finish
	note_path.add_child(new_note)

#Activates particles and changes trans ring colour to give the illusion
func show_pressed_effect() -> void:
	particles.restart()
	trans_ring.self_modulate = beating_color
	effect_timer.start(bc.grace_time)

func _on_effect_timer_timeout() -> void:
	if is_lines:
		trans_ring.self_modulate = transparent_line_color
	else:
		trans_ring.self_modulate = transparent_ring_color

func check_accuracy(time_til_beat : float) -> void:
	if time_til_beat <= perfect_grace_time|| time_til_beat >= 0.5 - perfect_grace_time:
		text_color = perfect_color
		text_pop_up.set_pop("Perfect", Vector2(545,375), text_color, text_pop_up.DEFAULT_DURATION)
	elif time_til_beat <= great_grace_time|| time_til_beat >= 0.5 - great_grace_time:
		text_color = great_color
		text_pop_up.set_pop("Great", Vector2(545,375), text_color, text_pop_up.DEFAULT_DURATION)
	elif time_til_beat <= bc.grace_time|| time_til_beat >= 0.5 - bc.grace_time:
		text_color = good_color
		text_pop_up.set_pop("Good", Vector2(545,375), text_color, text_pop_up.DEFAULT_DURATION)
	else:
		text_color = bad_color
		text_pop_up.set_pop("Bad", Vector2(545,375), text_color, text_pop_up.DEFAULT_DURATION)
