class_name BeatController
extends Node

signal on_beat # signal for executing things on to the beat. 

@onready var main_music_player = $MainMusicPlayer
@onready var hihat_sound = $AudioStreamPlayer
@onready var test_interactive  : AudioStreamInteractive = load("res://Resources/test_interactive.tres")

@export var grace_time : float # +- time for checks

var beat_timer : Timer
var current_beat_time : float # time until beat is hit. 

var is_playing : bool # is music track playing?
var beat_duration : float # how many seconds a beat is (or till the next beat)
var current_music : AudioStreamInteractive
var counter : int = 0

# Latency
var time_begin
var time_delay
var previous_time = 0


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
	
	# Compensate for delay.
	var time : float = (Time.get_ticks_usec() - time_begin) / 1000000.0
	# Compensate for latency.
	time -= time_delay
	# May be below 0 (did not begin yet).
	time = max(0, time)
	
	#current_beat_time += time - previous_time
	#if current_beat_time >= beat_duration:
		#current_beat_time = 0
		#hihat_sound.stop()
		#hihat_sound.play()
	
	previous_time = time
	current_beat_time += delta
	
	if current_beat_time >= beat_duration:
		current_beat_time = 0
		#(main_music_player.stream as AudioStreamSynchronized).get_sync_stream(1).play()
		on_beat.emit()

# use this function to check when a input is on beat.
func is_on_beat() -> bool:
	if current_beat_time <= grace_time || current_beat_time >= beat_duration - grace_time:
		return true
	else:
		return false 

#region Internal
func start_music() -> void:
	is_playing = true
	current_beat_time = beat_duration
	
	# Get latency.
	time_begin = Time.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	
	main_music_player.play()
	#beat_timer.start()

func change_clip():
	counter += 1
	(main_music_player.get_stream_playback().switch_to_clip(counter%2))

func change_music(new_music : AudioStreamInteractive) -> void:
	current_music = new_music
	main_music_player.stream = current_music
	beat_duration = 60/120

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

#endregion
### Features we need
# 1. a timer that sends a signal every beat [Done]
# 2. a variable for grace period [Done]
# 3. a boolean to check is something is on beat [Done]
# 4: interactive music, switching to pieces of same bar/timestamp. [In progress]
# 5:  a function for setting fades between different music pieces [In progress]
# 6. ensure music timestamps are similar, if not redirect.
# 7. the check for on-beat is client-side or has leniancy for the client.


func transition_music(from_clip, to_clip):
	pass
func get_current_timestamp() -> float:
	return 0
