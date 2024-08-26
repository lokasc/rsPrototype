class_name BeatController
extends Node

signal on_beat # signal for executing things on to the beat. 

var beat_timer : Timer
var current_beat_time : float # time until beat is hit. 

@onready var hihat_sound = $AudioStreamPlayer
@onready var main_music_player = $MainMusicPlayer
@onready var test_interactive  : AudioStreamInteractive = load("res://Resources/test_interactive.tres")

var beat_duration : float # how many seconds a beat is (or till the next beat)
var current_music : AudioStreamInteractive
var is_playing : bool
var grace_time : float # +- time for checks

var counter : int = 0


func _enter_tree() -> void:
	GameManager.Instance.bc = self
	is_playing = false

func _ready() -> void:
	#beat_timer = $BeatTimer
	change_music(test_interactive)
	start_music()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		change_clip()
	
	
	if !is_playing: return
	current_beat_time += delta
	
	if current_beat_time >= beat_duration:
		current_beat_time = 0
		#hihat_sound.stop()
		#hihat_sound.play()
		on_beat.emit()

# TODO: change arguements to system time & BC script variables
func is_on_beat(BPM : int, current_time : float, grace_time : float) -> bool:
	var second_one_beat : float = 60.0/BPM
	if abs(current_time - second_one_beat) <= grace_time:
		return true
	else:
		return false 

func start_music() -> void:
	is_playing = true
	current_beat_time = beat_duration
	main_music_player.play()
	#beat_timer.start()

func change_clip():
	counter += 1
	(main_music_player.get_stream_playback() as AudioStreamPlaybackInteractive).switch_to_clip(counter%2)

func change_music(new_music : AudioStream) -> void:
	current_music = new_music
	main_music_player.stream = current_music
	beat_duration = 60.0/120
	
	# Godot's StreamInteractive is not flexible enough,
	# cant transition from this bar to the next bar.
	# Transition from calm to fast quicker.
	current_music.add_transition(
		0,  # index 0 is calm 
		1,  # index 1 is fast
		AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE,
		AudioStreamInteractive.TRANSITION_TO_TIME_SAME_POSITION,
		AudioStreamInteractive.FADE_AUTOMATIC,
		0.5
		 )
	
	# Transition from fast to calm slower
	current_music.add_transition(
		1, 
		0, 
		AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE,
		AudioStreamInteractive.TRANSITION_TO_TIME_SAME_POSITION,
		AudioStreamInteractive.FADE_AUTOMATIC,
		1
		 )

func transition_music(from_clip, to_clip):
	pass

@rpc("authority", "call_remote", "reliable")
func stc_check_timestamp(time : float) -> void:
	if abs(time - get_current_timestamp()) >= 0.5:
		cts_return_time_stamp(get_current_timestamp())
	pass

# send to server client's time_stamp
@rpc("any_peer", "reliable")
func cts_return_time_stamp(client_time : float) -> void:
	pass

# Pass timestamp and time left on timers 
func sync_music() -> void:
	pass

func get_current_timestamp() -> float:
	return 0

### Features we need
# 1. a timer that sends a signal every beat [Done]
# 2. a variable for grace period [Done]
# 3. a boolean to check is something is on beat [in progress]
# 4: interactive music, switching to pieces of same bar/timestamp. 
# 5:  a function for setting fades between different music pieces
# 6. ensure music timestamps are similar, if not redirect.
# 7. the check for on-beat is client-side or has leniancy for the client.
