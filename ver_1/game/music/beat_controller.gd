class_name BeatController
extends Node

const BPM = 120 ## Beats per minute

signal on_beat ## signal for executing things on to the beat. 

static var Instance : BeatController

@onready var main_music_player : AudioStreamPlayer = $MainMusicPlayer 
@onready var test_interactive  : AudioStream = load("res://Resources/test_interactive.tres")

@export_range(0.01 , 0.5, 0.01, "or_greater") var grace_time : float = 0.01 ## +- time for checks

# is_on_beat replication
var replicated_on_beat_bool : bool = false

var current_beat_time : float ## time until beat is hit. 
var is_playing : bool ## is music track playing?

var beat_duration : float ## how many seconds a beat is (or till the next beat)
var counter : int = 0 ## used for switching songs with m1

# Latency
var time
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

# Beats.
var current_beat : int
var prev_beat : int = -1 # or else we have a delay of 1 beat

func _init() -> void:
	Instance = self

func _enter_tree() -> void:
	GameManager.Instance.bc = self
	is_playing = false

func _ready() -> void:
	main_music_player.stream = test_interactive
	beat_duration = 60.0/BPM
	current_global_bg_clip = main_music_player.stream.initial_clip

func _process(delta: float) -> void:
	if !is_playing: return
	process_actual_audio_time()
## Is the current moment on beat? (Accounting for grace)
func is_on_beat() -> bool:
	#print(str(multiplayer.is_server()) + " - Current_time: " + str(current_beat_time))
	#if current_beat_time <= grace_time || current_beat_time >= beat_duration - grace_time:
	if get_time_til_next_beat() <= grace_time || get_time_til_next_beat() >= beat_duration - grace_time:
		print("on beat")
		return true
	else:
		print("not on beat")
		return false 

@rpc("any_peer", "call_remote", "reliable")
func send_replicated_on_beat(local_value):
	replicated_on_beat_bool = local_value

#region Internal
func start_music(start_position : float = 0) -> void:
	is_playing = true
	
	# so that the first beat is at 0s
	current_beat_time = beat_duration
	
	# Get latency.
	time_begin = Time.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	main_music_player.play(0)
	$MimicPlayer.play(0)
	playback = main_music_player.get_stream_playback()

## Calculates if exactly on beat and accounts for audio delay.
func process_actual_audio_time(): 
	
	# when play() is executed, its not actually excuted immediately,
	# the function starts the mixing of a chunk of the song and thus
	# you can then hear it: therefore you need to get the "time to next mix"
	
	# get_playback_position() gets the current time of the song,
	# since its not always updated per frame, we need to do more to find the
	# exact position
	
	# Theres is a bug in godot with getting position with audio interactive.
	# Thus the work around is to use 2 audio players, 
	# One to play music, the other to track. (there might be multiple audio delay)
	time = $MimicPlayer.get_playback_position() + AudioServer.get_time_since_last_mix()
	time -= AudioServer.get_output_latency()
	#print(time)
	# Calculate the current beat of the song.
	current_beat = floor(time/0.5)
	process_beat()
	
	# Get the current beat in the song without software clock (delta)

func process_beat() -> void:
	# Check if we are still in the same beat (return if is)
	#print(current_beat)
	if prev_beat >= current_beat: return
	
	# Emit signal
	#print("emited")
	prev_beat = current_beat
	on_beat.emit()

# Changes backgrounud music
@rpc("authority", "reliable", "call_remote")
func stc_change_bg_music(type : BG_TRANSITION_TYPE):
	change_bg(type)

@rpc("authority", "reliable", "call_local")
func stc_start_music(sent_time : float):
	# account for delay in sending in the rpc
	var arrive_time : float =  Time.get_unix_time_from_system()
	var diff : float = arrive_time - sent_time
	
	if diff <= 0.05:
		start_music(0)
		return
	else:
		start_music(diff)

#endregion
### Features we need
# 1. a timer that sends a signal every beat [Done]
# 2. a variable for grace period [Done]
# 3. a boolean to check is something is on beat [Done]
# 4: interactive music, switching to pieces of same bar/timestamp. [Done]
# 5:  a function for setting fades between different music pieces [Done]
# 6. ensure music timestamps are similar, if not redirect -> done at the start [Done]
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
			
			playback.switch_to_clip_by_name("early_bgm")
			current_bg_clip = type
			
		BG_TRANSITION_TYPE.MID_GAME:
			if multiplayer.is_server(): stc_change_bg_music.rpc(type)
				
			current_global_bg_clip = type
	
			# prevent changing clips if current clip is local
			if !is_current_clip_global(): return
			
			playback.switch_to_clip_by_name("early_bgm")
			current_bg_clip = type
		BG_TRANSITION_TYPE.LATE_GAME: 
			if multiplayer.is_server(): stc_change_bg_music.rpc(type)
			current_global_bg_clip = type
			
			if !is_current_clip_global(): return
			
			playback.switch_to_clip_by_name("early_bgm")
			current_bg_clip = type
		BG_TRANSITION_TYPE.BOSS: # rpc call
			if multiplayer.is_server(): stc_change_bg_music.rpc(type)
			current_global_bg_clip = type
			
			if !is_current_clip_global(): return
			
			playback.switch_to_clip_by_name("early_bgm")
			current_bg_clip = type
		BG_TRANSITION_TYPE.LOW_HP:
			current_bg_clip = type
			playback.switch_to_clip_by_name("early_bgm_death")
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

# returns time_til_next_beat as a float between 0.0 - 5.0, with 0.0 being onbeat
func get_time_til_next_beat() -> float:
	if time == null: return 0
	var time_til_next_beat: float = clamp(time - int(time) , 0, 1)
	if time_til_next_beat >= 0.5:
		time_til_next_beat = clamp(time - int(time) - 0.5 , 0, 1)
	return time_til_next_beat
