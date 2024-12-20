# meta-description: Skeleton for creating abilities, handles cooldowns & upgrading logic, shows all virtual functions. 
class_name TrebbieDash
extends BaseAbility

@export_category("Game stats")
@export var initial_dmg : float
@export var initial_cd : float
@export var zero_cd : bool = false
@export var speed : int
@export var distance : int

@export_category("Music sync stats")
@export var cd_reducion : float = 1.0

var original_pos := Vector2.ZERO
var new_position := Vector2.ZERO
var direction := Vector2.ZERO
var duration : float = 0

@onready var hitbox : Area2D = $HitBox

@onready var beat_sync_effects : GPUParticles2D = $"../Sprites/BeatSyncEffect"
@onready var dash_effect_particles : GPUParticles2D = $"../Sprites/RotatingWeapon/GPUParticles2D"
@onready var collisionbox : CollisionShape2D = $CollisionBox/CollisionShape2D


func _init():
	super()
	pass

func _enter_tree():
	action_icon_path = "res://assets/icons/trebbie_dash_icon.png"
	desc = "Become invincible and dash towards mouse direction.\nBeat Sync: Reduces cooldown by 70%"

func _ready() -> void:
	super()
	# connect signal
	hitbox.area_entered.connect(on_hit)
	# initialise hitboxes
	hitbox.visible = false
	hitbox.monitoring = false
	collisionbox.disabled = true
	collisionbox.visible = false
	
	# Temporary dash effects
	dash_effect_particles.emitting = false
	
	if zero_cd:
		a_stats.cd = 0

func enter():
	_reset()
	if hero == null: return
	
	# Store hero position and the direction when the ability is used
	original_pos = hero.position
	a_stats.cd = initial_cd
	set_ability_to_hero_stats()
	
	if is_synced:
		a_stats.cd *= cd_reducion / hero.char_stats.mus
		beat_sync_effects.restart()
	
	look_at(hero.input.get_mouse_position())
	direction = original_pos.direction_to(hero.input.get_mouse_position())
	duration = 0
	new_position = original_pos + direction * distance
	
	hero.IS_INVINCIBLE = true
	
	# enable hitboxes
	collisionbox.disabled = false
	collisionbox.visible = true
	hitbox.monitoring = true
	hitbox.visible = true
	
	# Temporary dash effects
	dash_effect_particles.emitting = true
	hero.ability_used.emit(self)
	ability_used.emit()

func exit():
	super() # starts cd here.
	start_cd()
	# disable hitboxes
	collisionbox.disabled = true
	collisionbox.visible = false
	hitbox.visible = false
	hitbox.monitoring = false
	hero.IS_INVINCIBLE = false
	is_synced = false
	
	# Temporary dash effects
	dash_effect_particles.emitting = false

func update(_delta: float):
	super(_delta)
	hero.input.ability_2 = false

func physics_update(_delta: float):
	super(_delta)
	# Ability movement
	duration += _delta
	
	# velocity is pixels per second. 
	# move towards moves the position to a new position by x amount pEr frame. 
	# this would just maen 10 pixels per physics update frame.
	hero.velocity = direction * speed * Engine.physics_ticks_per_second
	#hero.position = hero.position.move_toward(new_position, speed)
	if hero.position == new_position or duration >= 0.35:
		state_change.emit(self, "TrebbieAttack")
	hero.move_and_slide()

func _process(delta):
	super(delta)
	pass
	
func on_hit(area : Area2D):
	if !multiplayer.is_server(): return
	
	# typecasting
	var character : BaseCharacter = null 
	if area.get_parent() is BaseCharacter:
		character = area.get_parent()

	# do not execute on non-characters or nulls
	if !character && !(character is BaseCharacter): return

	if character is BaseEnemy:
		character.hit.connect(lifesteal)
		character.take_damage(get_multiplied_atk())
		character.hit.disconnect(lifesteal)
	if character is BaseHero:
		if character == hero: return # we dont want trebbie to heal self with dash.
		character.gain_health(hero.tip_heal_amount)

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade():
	super()

func set_ability_to_hero_stats() -> void:
	a_stats.aoe = hero.char_stats.aoe ; scale = a_stats.aoe * Vector2.ONE
	a_stats.atk = initial_dmg * hero.get_total_dmg()/hero.initial_damage
	if not zero_cd: a_stats.cd = initial_cd * hero.char_stats.cd


func _on_dash_timer_timeout() -> void:
	state_change.emit(self, "TrebbieAttack")
