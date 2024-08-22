# meta-description: Skeleton for creating abilities, handles cooldowns & upgrading logic, shows all virtual functions. 
class_name BassheartFreeze
extends BaseAbility

@export_category("Game stats")
@export var initial_dmg : int
@export var initial_cd : int
## time it takes to charge
@export var charge_duration : float
## time it takes to shoot out the wave
@export var duration : float
@export var zero_cd : bool = false

@export_category("Freeze stats")
@export var freeze_duration : float
@export var unfreeze_dmg : int
@export var dmg_threshold : int

var is_charging : bool

@onready var wave_timer : Timer = $WaveTimer
@onready var charge_timer : Timer = $ChargeTimer
@onready var hitbox : Area2D = $HitBox
@onready var indicator : Area2D = $IndicatorBox

# Initialize abilities
# WARNING: export variables wont be avaliable on init, use enter_tree
func _init() -> void:
	super()
	pass

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree() -> void:
	a_stats.cd = initial_cd
	a_stats.atk = initial_dmg
	pass

func _ready() -> void:
	hitbox.area_entered.connect(on_hit)
	hitbox.visible = false
	hitbox.monitoring = false
	indicator.visible = false
	indicator.monitoring = false
	if zero_cd:
		a_stats.cd = 0

# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func enter() -> void:
	super()
	is_charging = true
	charge_timer.start(charge_duration)
	indicator.visible = true
	indicator.monitoring = true

func _on_charge_timer_timeout() -> void:
	hitbox.monitoring = true
	hitbox.visible = true
	
	indicator.visible = false
	indicator.monitoring = false
	is_charging = false
	wave_timer.start(duration)

func _on_wave_timer_timeout() -> void:
	hero.input.canMove = true
	hitbox.monitoring = false
	hitbox.visible = false
	state_change.emit(self, "BassheartAttack")

func exit() -> void:
	super() # starts cd here.
	start_cd()

func update(_delta: float) -> void:
	super(_delta)
	pass

func physics_update(_delta: float) -> void:
	super(_delta)
	if is_charging:
		hero.input.canMove = false
		look_at(hero.input.get_mouse_position())

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var enemy = area.get_parent() as BaseEnemy
	if enemy == null: return
	
	# TODO: not networked yet
	# need to calculate how much damage based on 
	# the attack value of this ability + my character's attack value
	enemy.take_damage(get_multiplied_atk())
	hero.gain_health(initial_dmg*hero.char_stats.hsg)
	
	#This comparison has to be added to prevent applying status twice, also bugs out freeze code
	if enemy.frozen == false:
		enemy.add_status("Freeze", [unfreeze_dmg,freeze_duration,dmg_threshold])

# Call this to start cooldown.
func start_cd() -> void:
	super()

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
