class_name BassheartJump
extends BaseAbility

@export_category("Game stats")
@export var initial_shields : float
@export var shield_duration : float
@export var active_duration : float
@export var initial_cd : int
@export var zero_cd : bool = false
## How far the hero jumps
@export var distance : int
## Time it takes to land, NOTE this will not match up with the effect, you will have to change the key time to the same as the landing time
@export var landing_time : float

@export_category("Empowered game stats")
@export var is_empowered : bool
@export var initial_dmg : float
@export var shield_multiplier : float

@export_category("Beat sync stats")
@export var sync_additional_shield : float
@export var sync_dmg_multiplier : float
## The amount of time allowed for sync before landing
@export var landing_grace_time : float 

@export_subgroup("Curve Parameters") 
## Determines how steep the jump is starting
@export var curve_in : int
## Determines how steep the jump is ending
@export var curve_out : int
## Determines the amplitude of the jump
@export var curve_amp : float
## Determines how much the curve diminishes, the higher the number the more it reduces, the smaller the number the less it reduces up to a limit of 0.37
@export var curve_red : float

# Jumping Curve Variables
var air_time : float		# Current time while jumping
var direction : Vector2		# The normalised direction of the mouse from the hero position
var curve_amp_reset : float	# The curve_amp set in the inspector
var original_pos : Vector2	# The position of where the hero jumped from
var current_pos : Vector2	# The current position of the hero
var inter_pos : Vector2		# The intermediate position of the curve
var inter_in_pos : Vector2	# Determines how fast the hero curves into inter_pos
var inter_out_pos : Vector2	# Determines how fast the hero curves out of inter_pos
var landing_pos : Vector2	# The position of the landing point
var new_position : Vector2	# same as landing_pos, used for items.

var has_started_hit_timer : bool = false # to prevent the hit timer from restarting
var has_synced : bool = false # different from is_synced, is_sync is for entering ability, has_sync is for the beat sync logic within the ability
var failed_sync : bool = false # to prevent player from spamming the button

@onready var hitbox : Area2D = $HitBox
@onready var path_follow : PathFollow2D = $Path2D/PathFollow2D
@onready var path : Path2D = $Path2D
@onready var hit_timer : Timer = $HitTimer

@onready var beat_sync_effects : GPUParticles2D = $"../Sprites/BeatSyncEffect"


# moving bassheart via velocity: VEL = (POS - OLD_POS) / Delta
var old_pos : Vector2

func _init() -> void:
	super()
	pass

func _enter_tree() -> void:
	action_icon_path = "res://assets/icons/bassheart_jump_icon.png"
	desc = "Jump towards a location providing shields to allies when landing.\nBeat Sync: Provides additional shields.\nEmpowered: Provides additional shields and does damage"

func _ready() -> void:
	super()
	# connect signal
	hitbox.area_entered.connect(on_hit)
	# initialise hitboxes
	hitbox.visible = false
	hitbox.monitoring = false
	if zero_cd:
		a_stats.cd = 0
	
	curve_amp_reset = curve_amp
	# curve reduction has a lower limit, if too low, the curve would be bigger than curve amp at the start
	if curve_red < 0.37:
		curve_red = 0.37

func enter() -> void:
	
	# Dont use super, need to emit signal after calculation
	# and assignment
	_reset()
	if hero == null: return
	
	# Reseting variables
	air_time = 0
	path_follow.progress_ratio = 0
	curve_amp = curve_amp_reset
	set_ability_to_hero_stats()
	
	has_started_hit_timer = false
	has_synced = false
	failed_sync = false
	
	hero.IS_INVINCIBLE = true
	is_empowered = hero.is_empowered # Checks on enter
	
	# Setting curve values
	original_pos = hero.position
	old_pos = original_pos
	direction = original_pos.direction_to(hero.input.get_mouse_position())
	landing_pos = original_pos + direction * distance
	new_position = landing_pos
	
	hero.ability_used.emit(self)
	ability_used.emit()
	
	get_curve_points()
	set_curve_points()
	hero.animator.play("jump")
	
	if is_synced:
		beat_sync_effects.restart()

func exit() -> void:
	super() # starts cd here.
	start_cd()
	# disable hitboxes
	hitbox.visible = false
	hitbox.monitoring = false
	
	hero.IS_INVINCIBLE = false
	if is_empowered:
		hero.reset_meter()

func update(delta: float) -> void:
	super(delta)
	air_time += delta
	if air_time >= landing_time and has_started_hit_timer == false:
			hit_timer.start(active_duration + landing_grace_time)
			hitbox.visible = true
			hitbox.monitoring = true
			has_started_hit_timer = true
	if is_synced:
		if hero.input.ability_2:
			if air_time >= landing_time - landing_grace_time and hero.input.is_on_beat:
				if not failed_sync:
					beat_sync_effects.restart()
					has_synced = true
			else: 
				failed_sync = true
				has_synced = false
	hero.move_and_slide()
	hero.input.ability_2 = false

func physics_update(delta: float) -> void:
	super(delta)
	# Ability movement
	path_follow.progress_ratio += delta/landing_time
	hero.velocity = (path_follow.position - old_pos) / delta
	old_pos = path_follow.position
	#hero.position = path_follow.position

func _process(delta : float) -> void:
	super(delta)
	pass
	
func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
	var character : BaseCharacter = null 
	
	if area.get_parent() is BaseCharacter:
		character = area.get_parent()

	# do not execute on non-characters or nulls
	if !character && !(character is BaseCharacter): return
	
	if is_empowered:
		if character is BaseEnemy:
			character.hit.connect(lifesteal)
			if has_synced:
				character.take_damage(get_multiplied_atk() * sync_dmg_multiplier * hero.char_stats.mus)
			else: character.take_damage(get_multiplied_atk())
			character.hit.disconnect(lifesteal)
		if character is BaseHero:
			if has_synced:
				character.gain_shield((initial_shields + sync_additional_shield * hero.char_stats.mus) * shield_multiplier, a_stats.dur)
			else: character.gain_shield(initial_shields * shield_multiplier, a_stats.dur)
	else:
		if character is BaseHero:
			if has_synced:
				character.gain_shield(initial_shields + sync_additional_shield * hero.char_stats.mus, a_stats.dur)
			else: character.gain_shield(initial_shields, a_stats.dur)

func get_curve_points() -> void:
	if direction.x <0: # so that the hero jumps upwards when moving left
		curve_amp *= -1 
	if direction.y <0: # diminishes the jumping curve when aiming more vertically
		curve_amp = curve_amp * (1 + direction.y) * curve_red ** (direction.y)
	else:
		curve_amp = curve_amp * (1 - direction.y) * curve_red ** (-direction.y)
	inter_pos = (original_pos + landing_pos)/2 + Vector2(direction.y, -direction.x) * curve_amp
	inter_out_pos = direction * curve_out
	inter_in_pos = direction * curve_in * -1

func set_curve_points() -> void:
	# Setting curve points
	path.curve.set_point_position(0,original_pos)
	path.curve.set_point_in(1, inter_in_pos)
	path.curve.set_point_position(1,inter_pos)
	path.curve.set_point_out(1, inter_out_pos)
	path.curve.set_point_position(2,landing_pos)

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade() -> void:
	super()

func set_ability_to_hero_stats() -> void:
	a_stats.aoe = hero.char_stats.aoe ; scale = a_stats.aoe * Vector2.ONE
	a_stats.atk = initial_dmg * hero.get_total_dmg()/hero.initial_damage
	a_stats.cd = initial_cd * hero.char_stats.cd
	a_stats.dur = shield_duration * hero.char_stats.dur

func _on_hit_timer_timeout() -> void:
	state_change.emit(self, "BassheartAttack")
