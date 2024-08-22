# meta-description: Skeleton for creating abilities, handles cooldowns & upgrading logic, shows all virtual functions. 
class_name BassheartJump
extends BaseAbility

@export_category("Game stats")
@export var initial_shields : int
@export var hit_duration : float
@export var initial_cd : int
@export var zero_cd : bool = false
## How far the hero jumps
@export var distance : int
## Time it takes to land
@export var landing_time : float

@export_category("Empowered game stats")
@export var initial_dmg : int
@export var shield_multiplier : float

@export_subgroup("Curve Parameters") 
## Determines how steep the jump is starting
@export var curve_in : int
## Determines how steep the jump is ending
@export var curve_out : int
## Determines the amplitude of the jump
@export var curve_amp : float
## Determines how much the curve diminishes, the higher the number the more it reduces, the smaller the number the less it reduces up to a limit of 0.37
@export var curve_red : float

var air_time : float		# Current time while jumping
var hit_time : float		# Current time while hitting
var direction : Vector2		# The normalised direction of the mouse from the hero position
var curve_amp_reset : float	# The curve_amp set in the inspector
var original_pos : Vector2	# The position of where the hero jumped from
var current_pos : Vector2	# The current position of the hero
var inter_pos : Vector2		# The intermediate position of the curve
var inter_in_pos : Vector2	# Determines how fast the hero curves into inter_pos
var inter_out_pos : Vector2	# Determines how fast the hero curves out of inter_pos
var landing_pos : Vector2	# The position of the landing point



@onready var hitbox : Area2D = $HitBox
@onready var path_follow : PathFollow2D = $Path2D/PathFollow2D
@onready var path : Path2D = $Path2D

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
	hit_time = 0
	path_follow.progress_ratio = 0
	curve_amp = curve_amp_reset
	
	hero.IS_INVINCIBLE = true
	
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
	
	hero.IS_INVINCIBLE = false
	if hero.is_empowered:
		hero.reset_meter()
	
func update(delta: float) -> void:
	super(delta)
	air_time += delta
	if air_time >= landing_time:
		hit_time += delta
		hitbox.visible = true
		hitbox.monitoring = true
		if hit_time >= hit_duration:
			state_change.emit(self, "BassheartAttack")

func physics_update(delta: float) -> void:
	super(delta)
	# Ability movement
	path_follow.progress_ratio += delta/landing_time
	hero.position = path_follow.position

func _process(delta) -> void:
	super(delta)
	pass
	
func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	var character : BaseHero = null
	var enemy : BaseEnemy = null
	# typecasting
	if area.get_parent() is BaseHero:
		character = area.get_parent()
	if area.get_parent() is BaseEnemy:
		enemy = area.get_parent()
	if character == null and enemy == null: return
	
	if hero.is_empowered:
		if enemy != null:
			enemy.take_damage(get_multiplied_atk())
		if character != null:
			character.gain_shield(initial_shields * shield_multiplier)
		hero.gain_health(get_multiplied_atk() * hero.char_stats.hsg)
	elif character != null:
		character.gain_shield(initial_shields)
# This func is used for auto_attack, dont change this.
func use_ability() -> void:
	if is_on_cd: return
	super()

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade() -> void:
	super()

# Called automatically when ability cd finishes, override this to addd functionality when cd finishes
func _on_cd_finish() -> void:
	_reset()

# Resets ability, lets players to use it again, override this to add functionality.
func _reset() -> void:
	super()

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
