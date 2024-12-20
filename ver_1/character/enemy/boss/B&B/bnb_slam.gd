class_name BnBSlam
extends BossAbility

@export var is_tgt : bool = false
@export var slam_range : float = 5
@onready var slam_area : Area2D = $SlamArea


var s_current_time : float = 0
var active_duration : float = 0.1
# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func _ready() -> void:
	slam_area.get_child(0).shape.radius = slam_range

func enter() -> void:
	super()
	slam_area.monitoring = true
	slam_area.get_child(0).debug_color = Color("ff8bffcf")
	
	# calculate fill time and phase 1 changes
	calculate_fill_time()

func update(delta) -> void:
	s_current_time += delta
	# ensure that player cannot move during the animation, due to kb also altering this bool during the slam.
	GameManager.Instance.local_player.input.canMove = false
	if s_current_time >= active_duration:
		on_slam_animation_finish()

func exit() -> void:
	GameManager.Instance.local_player.input.canMove = true
	slam_area.monitoring = false
	slam_area.get_child(0).debug_color = Color("aafbfa40")
	s_current_time = 0

func on_slam_animation_finish() -> void:
	if is_tgt: 
		change_state_phase_one()

func change_state_phase_one() -> void:
	#printerr(boss.phase)
	if boss.phase == 1:
		#state_change.emit(self, "BnBRain")
		state_change.emit(self, "BnBRing")
	elif boss.phase == 2:
		state_change.emit(self, "BnBRain")
	elif boss.phase == 3:
		boss.state_change_from_any("null")
		(boss as BeethovenAndBiano).p3_slam_ended = true

func _on_slam_area_hit(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
		
	if !character: return 	# do not execute on non-characters or nulls
	character.add_status("Knockback", [slam_range-(character.global_position.distance_to(global_position)), global_position, 12])

# changes the duration of the slam. 
func calculate_fill_time() -> void:
	if !is_tgt: return
	match boss.phase:
		1:
			var intro_duration = 8
			active_duration = intro_duration
			GameManager.Instance.bc.change_bg(BeatController.BG_TRANSITION_TYPE.BNB_INTRO)
			GameManager.Instance.boss_cinematic_camera_move(self.boss.char_id, self.global_position, 4, 4)
			
			# Waits until camera gets to the middle then shakes.
			await get_tree().create_timer(4.5).timeout # I AM NOT QUITE SURE WHETHER THIS LINE OF CODE WILL BREAK EVERYTHING INCLUDING SYNC AND TIMING.
			GameManager.Instance.screen_shake(8, 2)
			boss.invulnerable = false
		2:
			# Set the piano scream/battlecry for the remaining time left + mp3 fill time.
			active_duration = GameManager.Instance.bc.get_time_til_next_bar() + 4
			GameManager.Instance.bc.change_bg(BeatController.BG_TRANSITION_TYPE.BNB_FILL)
			
			# Turns on auto-advance for fill and go to phase 2 right after
			GameManager.Instance.bc.interactive_resource.set_clip_auto_advance(6 ,AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
			GameManager.Instance.bc.interactive_resource.set_clip_auto_advance_next_clip(6, 4)
			GameManager.Instance.boss_cinematic_camera_move(self.boss.char_id, self.global_position, active_duration-4, 4)
			
			# Waits until camera gets to the middle then shakes.
			await get_tree().create_timer(active_duration-4).timeout
			GameManager.Instance.screen_shake(8, 1.25)
		3:
			# Set the piano scream/battlecry for the remaining time left + mp3 fill time.
			active_duration = GameManager.Instance.bc.get_time_til_next_bar() + 4
			GameManager.Instance.bc.change_bg(BeatController.BG_TRANSITION_TYPE.BNB_FILL)
			
			# Turns on auto-advance for fill and go to phase 3 right after
			GameManager.Instance.bc.interactive_resource.set_clip_auto_advance(6 ,AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
			GameManager.Instance.bc.interactive_resource.set_clip_auto_advance_next_clip(6, 5)
			GameManager.Instance.boss_cinematic_camera_move(self.boss.char_id, self.global_position, active_duration-4, 4)
			
			
			await get_tree().create_timer(active_duration-4).timeout
			GameManager.Instance.screen_shake(12, 3)
