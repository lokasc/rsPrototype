class_name BassheartJump
extends BaseAbility

@export_category("Game stats")
@export var initial_shields : int
@export var shield_duration : float
@export var active_duration : float
@export var initial_cd : int
@export var zero_cd : bool = false
## How far the hero jumps
@export var distance : int
## Time it takes to land
@export var landing_time : float

@export_category("Empowered game stats")
@export var is_empowered : bool
@export var initial_dmg : int
@export var shield_multiplier : float

@export_category("Beat sync stats")
@export var sync_shield_multiplier : float
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

var has_triggered : bool = false # to prevent the hit timer from restarting
var has_synced : bool = false
var failed_sync : bool = false # to prevent player from spamming the button

@onready var hitbox : Area2D = $HitBox
@onready var path_follow : PathFollow2D = $Path2D/PathFollow2D
@onready var path : Path2D = $Path2D
@onready var hit_timer : Timer = $HitTimer

func _init() -> void:
	super()
	pass

func _enter_tree() -> void:
	a_stats.cd = initial_cd
	a_stats.atk = initial_dmg
	a_stats.shields = initial_shields
	pass

func _ready() -> void:
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
	super()
	
	# Reseting variables
	air_time = 0
	path_follow.progress_ratio = 0
	curve_amp = curve_amp_reset
	
	has_triggered = false
	has_synced = false
	failed_sync = false
	
	hero.IS_INVINCIBLE = true
	is_empowered = hero.is_empowered # Checks on enter
	
	# Setting curve values
	original_pos = hero.position
	direction = original_pos.direction_to(hero.input.get_mouse_position())
	landing_pos = original_pos + direction * distance
	
	get_curve_points()
	set_curve_points()
	

func exit() -> void:
	super() # starts cd here.
	start_cd()
	# disable hitboxes
	hitbox.visible = false
	hitbox.monitoring = false
	
	has_synced = false
	hero.IS_INVINCIBLE = false
	if is_empowered:
		hero.reset_meter()
	
func update(delta: float) -> void:
	super(delta)
	
	if air_time >= landing_time and has_triggered == false:
		hit_timer.start(active_duration)
		hitbox.visible = true
		hitbox.monitoring = true
		has_triggered = true
	elif air_time >= landing_time - landing_grace_time and hero.input.ability_2 and failed_sync == false:
		if hero.input.is_on_beat:
			has_synced = true
			print("synced")
		else: failed_sync == true
			
		
	else: air_time += delta

func physics_update(delta: float) -> void:
	super(delta)
	# Ability movement
	path_follow.progress_ratio += delta/landing_time
	hero.position = path_follow.position

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
			if has_synced:
				character.take_damage(get_multiplied_atk() * sync_dmg_multiplier)
			else: character.take_damage(get_multiplied_atk())
		if character is BaseHero:
			if has_synced:
				character.gain_shield(initial_shields * shield_multiplier * sync_shield_multiplier, shield_duration)
			else: character.gain_shield(initial_shields * shield_multiplier, shield_duration)
		hero.gain_health(get_multiplied_atk() * hero.char_stats.hsg)
	else:
		if character is BaseHero:
			if has_synced:
				character.gain_shield(initial_shields * sync_shield_multiplier, shield_duration)
			else: character.gain_shield(initial_shields, shield_duration)

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

func use_ability() -> void:
	if is_on_cd: return
	super()

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade() -> void:
	super()

func _on_cd_finish() -> void:
	_reset()

func _reset() -> void:
	super()

func _on_hit_timer_timeout() -> void:
	state_change.emit(self, "BassheartAttack")
