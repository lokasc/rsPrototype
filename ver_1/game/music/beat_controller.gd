class_name BeatController
extends Node

const BPM = 120 ## Beats per minute

signal on_beat ## signal for executing things on to the beat. 

@onready var main_music_player = $MainMusicPlayer 
@onready var test_interactive  : AudioStream = load("res://Resources/test_interactive.tres")

@export_range(0.01 , 0.5, 0.01, "or_greater") var grace_time : float = 0.01 ## +- time for checks
var current_beat_time : float ## time until beat is hit. 
var is_playing : bool ## is music track playing?

var beat_duration : float ## how many seconds a beat is (or till the next beat)
var counter : int = 0 ## used for switching songs with m1

# Latency
var time_begin
var time_delay
var previous_time = 0

# Clips
enum BG_TRANSITION_TYPE {
	EARLY_GAME,	#global -> all should hear
	MID_GAME,	#global
	LATE_GAME,	#global
	BOSS,	# global
	LOW_HP, # local -> only player can hear it
	DEAD,  # local
	}

## Note, global refers to the clip thats supposed to play
## local refers to the client-side override to current clip
## current_bg_clip can be local or global.
var current_global_bg_clip : BG_TRANSITION_TYPE ## current global clip.
var current_bg_clip : BG_TRANSITION_TYPE # current clip

var playback : AudioStreamPlayback

func _enter_tree() -> void:
	GameManager.Instance.bc = self
	is_playing = false

func _ready() -> void:
	main_music_player.stream = test_interactive
	beat_duration = 60.0/BPM
	current_global_bg_clip = main_music_player.stream.initial_clip

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") && multiplayer.is_server():
		if current_bg_clip == BG_TRANSITION_TYPE.EARLY_GAME:
			change_bg(BG_TRANSITION_TYPE.LOW_HP)
		else:
			change_bg_from_local_to_global()
	
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
	playback = main_music_player.get_stream_playback()

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

# Changes backgrounud music
@rpc("authority", "reliable", "call_remote")
func stc_change_bg_music(type : BG_TRANSITION_TYPE):
	change_bg(type)

@rpc("authority", "reliable", "call_local")
func stc_start_music():
	start_music()

#endregion
### Features we need
# 1. a timer that sends a signal every beat [Done]
# 2. a variable for grace period [Done]
# 3. a boolean to check is something is on beat [Done]
# 4: interactive music, switching to pieces of same bar/timestamp. [Done]
# 5:  a function for setting fades between different music pieces [Done]
# 6. ensure music timestamps are similar, if not redirect.
# 7. the check for on-beat is client-side or has leniancy for the client.

## Returns if the current clip is a global clip (low, mid, late & boss)
func is_current_clip_global() -> bool:
	if current_global_bg_clip != BG_TRANSITION_TYPE.LOW_HP || current_global_bg_clip != BG_TRANSITION_TYPE.DEAD:
		return true
	else:
		return false

## Change background music
func change_bg(type : BG_TRANSITION_TYPE) -> void:
	if playback == null: return
	
	match type:
		BG_TRANSITION_TYPE.EARLY_GAME:
			# only server changes client's global bg
			if multiplayer.is_server(): stc_change_bg_music.rpc(type)
			current_global_bg_clip = type
			
			if !is_current_clip_global(): return
			
			playback.switch_to_clip_by_name("Calm")
			current_bg_clip = type
			
		BG_TRANSITION_TYPE.MID_GAME:
			if multiplayer.is_server(): stc_change_bg_music.rpc(type)
				
			current_global_bg_clip = type
	
			# prevent changing clips if current clip is local
			if !is_current_clip_global(): return
			
			playback.switch_to_clip_by_name("Hard")
			current_bg_clip = type
		BG_TRANSITION_TYPE.LATE_GAME: 
			if multiplayer.is_server(): stc_change_bg_music.rpc(type)
			current_global_bg_clip = type
			
			if !is_current_clip_global(): return
			
			playback.switch_to_clip_by_name("Hard")
			current_bg_clip = type
		BG_TRANSITION_TYPE.BOSS: # rpc call
			if multiplayer.is_server(): stc_change_bg_music.rpc(type)
			current_global_bg_clip = type
			
			if !is_current_clip_global(): return
			
			playback.switch_to_clip_by_name("Hard")
			current_bg_clip = type
		BG_TRANSITION_TYPE.LOW_HP:
			current_bg_clip = type
			playback.switch_to_clip_by_name("Hard")
		BG_TRANSITION_TYPE.DEAD:
			current_bg_clip = type
		_:
			assert(false, "Error, wrong or no type given")

# WARNING: This should only be called by the server. Change from a local clip to global
func change_bg_from_local_to_global(player_id : int = 1) -> void:
	if player_id != 1 && multiplayer.is_server():
		stc_change_bg_to_global.rpc_id(player_id)
		return
	
	if !is_current_clip_global(): return
	current_bg_clip = current_global_bg_clip # need this line to ensure change_bg works as intended.
	change_bg(current_bg_clip)

@rpc("authority", "reliable", "call_remote")
func stc_change_bg_to_global():
	change_bg_from_local_to_global(-1)
