class_name TrebbieBuff
extends BaseAbility

@export_category("Game Stats")
@export var initial_cd : float
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

## The time window where it checks if the player pressed the same ability button and it's on beat for a recast
@export var recast_window : float

## The amount of recast allowed
@export var recast_amount : int = 3

var recast : int
var duration_time : float

@onready var bc : BeatController = GameManager.Instance.bc
@onready var beat_visual : BeatVisualizer = GameManager.Instance.ui.player_ui_layer.get_node("BeatVisualizerLines")
@onready var beat_visual2 : BeatVisualizer = GameManager.Instance.ui.player_ui_layer.get_node("BeatVisualizerLines2")
@onready var hitbox_shape : CollisionShape2D = $HitBox/CollisionShape2D
@onready var hitbox : Area2D = $HitBox
@onready var recast_timer : Timer = $BuffRecastTimer

@onready var beat_sync_effects : GPUParticles2D = $"../Sprites/BeatSyncEffect"
@onready var buff_particles : GPUParticles2D = $"../Sprites/BuffParticles2D"


# Initialize abilities
# WARNING: export variables wont be avaliable on init, use enter_tree
func _init() -> void:
	super()
	pass

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree() -> void:
	a_stats.dur = active_duration
	action_icon_path = "res://assets/icons/trebbie_buff_icon.png"
	desc = "Increases damage and heal/shield gain for allies in an area.\nBeat Sync: Reapplies buff with increasing area \nup to maximum of 3"

func _ready() -> void:
	super()
	hitbox.area_entered.connect(on_hit)
	hitbox.visible = false
	hitbox.monitoring = false
	buff_particles.emitting = false
	
	initial_effect_scale = Vector2.ONE
	if zero_cd:
		a_stats.cd = 0
	hitbox_shape.shape.radius = a_stats.aoe

func enter() -> void:
	super()
	hitbox.visible = true
	hitbox.monitoring = true
	buff_particles.emitting = true
	buff_particles.process_material.scale = initial_effect_scale
	buff_particles.show()
	duration_time = 0 
	recast = 0
	set_ability_to_hero_stats()
	
	if is_synced:
		hitbox_shape.shape.radius *= beat_sync_multiplier
		beat_visual.spawn_note(0.5, Vector2(-100,0))
		beat_visual2.spawn_note(0.5, Vector2(100,0))
		beat_visual.spawn_note(1, Vector2(-200,0))
		beat_visual2.spawn_note(1, Vector2(200,0))
		beat_visual.spawn_note(1.5, Vector2(-300,0))
		beat_visual2.spawn_note(1.5, Vector2(300,0))
		
		# Call this on the local player
		if hero.is_multiplayer_authority():
			beat_visual.show()
			beat_visual2.show()
		
		beat_sync_effects.restart()

func exit() -> void:
	super() # starts cd here.
	start_cd()
	hitbox.visible = false
	hitbox.monitoring = false
	buff_particles.emitting = false
	buff_particles.hide()
	
	if hero.is_multiplayer_authority():
		beat_visual.hide()
		beat_visual2.hide()
	is_synced = false

func update(delta: float) -> void:
	super(delta)
	duration_time += delta
	if duration_time >= active_duration and is_synced == false:
		state_change.emit(self, "TrebbieAttack")
	elif duration_time >= active_duration and is_synced == true: # Activated once, twice, thrice
		if hero.input.ability_1:
			beat_visual.check_accuracy(duration_time, 0.5, beat_visual.perfect_grace_time, beat_visual.great_grace_time, bc.grace_time)
			beat_visual2.check_accuracy(duration_time, 0.5, beat_visual.perfect_grace_time, beat_visual.great_grace_time, bc.grace_time)
		start_recast_logic()
	if hero.input.ability_2:
		state_change.emit(self, "TrebbieDash")
	hero.input.ability_1 = false

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
	
	# may do additional recast logic here
	character.add_status("DamageUp", [dmg_multiplier, status_duration * hero.char_stats.dur])
	character.add_status("HealShieldGainUp", [hsg_multiplier, status_duration * hero.char_stats.dur])

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade() -> void:
	super()

func start_recast_logic() -> void:
		hitbox.visible = false
		hitbox.monitoring = false
		buff_particles.hide()
		# Starts checking if player will press within recast window
		if recast_timer.is_stopped():
			recast_timer.start(recast_window)
		# Have to recast on beat
		if hero.input.ability_1 and hero.input.is_on_beat and recast < recast_amount:	# Activated twice (reactivated)
			recast_ability()
		# Resets if recasted too many times or didn't press on beat
		elif hero.input.ability_1:
			if recast >= recast_amount or hero.input.is_on_beat == false:
				buff_particles.emitting = false
				recast_timer.timeout.emit()
				state_change.emit(self, "TrebbieAttack")

func recast_ability():
	hitbox_shape.shape.radius *= beat_sync_multiplier * hero.char_stats.mus
	hitbox.visible = true
	hitbox.monitoring = true
	buff_particles.show()
	beat_sync_effects.restart()
	buff_particles.process_material.scale *= beat_sync_multiplier * hero.char_stats.mus
	duration_time = 0
	recast_timer.start(recast_window)
	recast += 1
	if recast > recast_amount - 1:
		beat_visual.hide()
		beat_visual2.hide()

func _on_buff_recast_timer_timeout() -> void:
	if recast <= recast_amount:
		state_change.emit(self, "TrebbieAttack")

func set_ability_to_hero_stats() -> void:
	a_stats.aoe = initial_area * hero.char_stats.aoe ; hitbox_shape.shape.radius = a_stats.aoe
	if not zero_cd: a_stats.cd = initial_cd * hero.char_stats.cd
