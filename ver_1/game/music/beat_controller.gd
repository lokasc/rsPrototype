class_name BeatController
extends Node

const BPM = 120 ## Beats per minute

signal on_beat ## signal for executing things on to the beat. 

@onready var main_music_player = $MainMusicPlayer
@onready var test_interactive  : AudioStream = load("res://Resources/test_interactive.tres")


@export_range(0.01 , 0.5, 0.01, "or_greater") var grace_time : float = 0.01 ## +- time for checks
var current_beat_time : float ## time until beat is hit. 
var is_playing : bool ## is music track playing?
var current_music : AudioStream ## current music thats playing or set

var beat_duration : float ## how many seconds a beat is (or till the next beat)
var counter : int = 0 ## used for switching songs with m1

# Latency
var time_begin
var time_delay
var previous_time = 0


func _enter_tree() -> void:
	GameManager.Instance.bc = self
	is_playing = false

func _ready() -> void:
	change_music(test_interactive)
	start_music()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		print(is_on_beat())
		change_clip(counter%2)
	
	if !is_playing: return
	process_actual_audio_time()

## Is the current moment on beat? (Accounting for grace)
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

## Calculates if exactly on beat and accounts for audio delay.
func process_actual_audio_time(): 
	# Get actual audio time independent of other systems.
	var time = (Time.get_ticks_usec() - time_begin) / 1000000.0
	# Compensate for latency.
	time -= time_delay
	# May be below 0 (did not begin yet).
	time = max(0, time)
	
	# calculate time diff
	current_beat_time += time - previous_time
	previous_time = time
	
	# check if exactly on beat (useful for ui sync)
	if current_beat_time >= beat_duration:
		current_beat_time = 0
		on_beat.emit()

## Change clip on the current stream
func change_clip(index : int) -> void:
	counter += 1
	(main_music_player.get_stream_playback().switch_to_clip(counter%2))

## Change stream with default clip set to 0
func change_stream(stream_index : int, clip_index: int  = 0) -> void:
	pass

func change_music(new_music : AudioStream) -> void:
	current_music = new_music
	main_music_player.stream = current_music
	beat_duration = 60.0/BPM

@rpc("authority", "call_remote", "reliable")
func stc_check_timestamp(time : float) -> void:
	if abs(time - get_current_timestamp()) >= 0.5:
		cts_return_time_stamp(get_current_timestamp())
	pass

# send to server client's time_stamp
@rpc("any_peer", "reliable")
func cts_return_time_stamp(_client_time : float) -> void:
	pass

# Pass timestamp and time left on timers 
func sync_music() -> void:
	pass

func get_current_timestamp() -> float:
	return 0
	
#endregion
### Features we need
# 1. a timer that sends a signal every beat [Done]
# 2. a variable for grace period [Done]
# 3. a boolean to check is something is on beat [Done]
# 4: interactive music, switching to pieces of same bar/timestamp. [Done]
# 5:  a function for setting fades between different music pieces [Done]
# 6. ensure music timestamps are similar, if not redirect.
# 7. the check for on-beat is client-side or has leniancy for the client.

enum BG_TRANSITION_TYPE {
	FRIENDLY_DEAD,
	LOW_HP,
	EARLY_GAME,
	MID_GAME,
	LATE_GAME,
	}

## Change background music
func change_bg(type : BG_TRANSITION_TYPE) -> void:
	match type:
		BG_TRANSITION_TYPE.EARLY_GAME:
			print("transition to early")
		BG_TRANSITION_TYPE.MID_GAME:
			print("transition to mid")
		BG_TRANSITION_TYPE.LATE_GAME:
			print("transition to late")
		_:
			printerr("Error, wrong or no type given")
