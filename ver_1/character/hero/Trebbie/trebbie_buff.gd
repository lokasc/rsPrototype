class_name TrebbieBuff
extends BaseAbility

@export_category("Game Stats")
@export var initial_cd : int
## duration of the ability applying the effect
@export var active_duration : float

@export var dmg_multiplier : float
@export var hsg_multiplier : float
## duration of the status effects
@export var status_duration : float 

## radius of the circle hitbox
@export var initial_area : int

@export var zero_cd : bool

@export_category("Beat Sync Stats")
## the area multiplier of the hitbox
@export var beat_sync_multiplier : float

## The time window allowed for a recast
@export var recast_window : float

## The amount of recast allowed
@export var recast_amount : int = 3

var recast : int
var duration_time : float

@onready var hitbox_shape : CollisionShape2D = $HitBox/CollisionShape2D
@onready var hitbox : Area2D = $HitBox
@onready var recast_timer : Timer = $BuffRecastTimer


# Initialize abilities
# WARNING: export variables wont be avaliable on init, use enter_tree
func _init() -> void:
	super()
	pass

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree() -> void:
	a_stats.cd = initial_cd
	a_stats.dur = active_duration
	a_stats.aoe = initial_area
	pass

func _ready() -> void:
	hitbox.area_entered.connect(on_hit)
	hitbox.visible = false
	hitbox.monitoring = false
	if zero_cd:
		a_stats.cd = 0
	hitbox_shape.shape.radius = a_stats.aoe

func enter() -> void:
	hitbox.visible = true
	hitbox.monitoring = true
	duration_time = 0 
	recast = 0
	set_ability_to_hero_stats()
	if is_synced:
		hitbox_shape.shape.radius *= beat_sync_multiplier
	super()

func exit() -> void:
	super() # starts cd here.
	start_cd()
	hitbox.visible = false
	hitbox.monitoring = false
	is_synced = false

func update(delta: float) -> void:
	super(delta)
	duration_time += delta
	if duration_time >= active_duration and is_synced == false:
		state_change.emit(self, "TrebbieAttack")
	elif duration_time >= active_duration and is_synced == true: # Activated once, twice, thrice
		start_recast_logic()
		
func physics_update(_delta: float) -> void:
	super(_delta)
	if hero.input.direction:
		hero.velocity = hero.input.direction * hero.char_stats.spd
	else:
		hero.velocity = hero.velocity.move_toward(Vector2.ZERO, hero.DECELERATION)
	hero.move_and_slide()
	pass

# Call this to start cooldown.
func start_cd() -> void:
	super()

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var character : BaseHero = area.get_parent() as BaseHero
	if character == null: return
	
	character.add_status("DamageUp", [dmg_multiplier, status_duration])
	character.add_status("HealShieldGainUp", [hsg_multiplier, status_duration])

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade() -> void:
	super()

# Called automatically when ability cd finishes, override this to addd functionality when cd finishes
func _on_cd_finish() -> void:
	_reset()

# Resets ability, lets players to use it again, override this to add functionality.
func _reset() -> void:
	super()

func start_recast_logic() -> void:
		hitbox.visible = false
		hitbox.monitoring = false
		# Starts checking if player will press within recast window
		if recast_timer.is_stopped():
			recast_timer.start(recast_window)
		# Have to recast on beat
		if hero.input.ability_1 and hero.input.is_on_beat and recast < recast_amount:	# Activated twice (reactivated)
			hitbox_shape.shape.radius *= beat_sync_multiplier 
			hitbox.visible = true
			hitbox.monitoring = true
			duration_time = 0
			recast_timer.stop()
			recast_timer.start(recast_window)
			recast += 1
		# Resets if recasted too many times or didn't press on beat
		elif hero.input.ability_1:
			if recast >= recast_amount or hero.input.is_on_beat == false:
				recast_timer.timeout.emit()
				state_change.emit(self, "TrebbieAttack")

func _on_buff_recast_timer_timeout() -> void:
	if recast <= recast_amount:
		state_change.emit(self, "TrebbieAttack")

func set_ability_to_hero_stats() -> void:
	a_stats.aoe = initial_area * hero.char_stats.aoe
	hitbox_shape.shape.radius = a_stats.aoe
