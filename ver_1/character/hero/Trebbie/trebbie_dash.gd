# meta-description: Skeleton for creating abilities, handles cooldowns & upgrading logic, shows all virtual functions. 
class_name TrebbieDash
extends BaseAbility

@export_category("Game stats")
@export var initial_dmg : int
@export var initial_cd : int
@export var zero_cd : bool = false
@export var speed : int
@export var distance : int

@export_category("Music sync stats")
@export var cd_reducion : float = 1.0

var original_pos = Vector2.ZERO
var direction = Vector2.ZERO

@onready var hitbox : Area2D = $HitBox
@onready var dash_effect_particles : GPUParticles2D = $"../Sprites/RotatingWeapon/GPUParticles2D"
# Current knockback, this will be changed when knockback code is added
@onready var collisionbox : CollisionShape2D = $CollisionBox/CollisionShape2D


func _init():
	super()
	pass

func _enter_tree():
	a_stats.cd = initial_cd
	a_stats.atk = initial_dmg
	pass

func _ready() -> void:
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
	super()
	# Store hero position and the direction when the ability is used
	original_pos = hero.position
	
	a_stats.cd = initial_cd
	set_ability_to_hero_stats()
	if is_synced:
		a_stats.cd *= cd_reducion
	look_at(hero.input.get_mouse_position())
	direction = original_pos.direction_to(hero.input.get_mouse_position())
	hero.IS_INVINCIBLE = true
	
	# enable hitboxes
	collisionbox.disabled = false
	collisionbox.visible = true
	hitbox.monitoring = true
	hitbox.visible = true
	
	# Temporary dash effects
	dash_effect_particles.emitting = true

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
	pass

func physics_update(_delta: float):
	super(_delta)
	# Ability movement
	var new_position : Vector2 = original_pos + direction * distance
	hero.position = hero.position.move_toward(new_position, speed)
	if hero.position == new_position:
		state_change.emit(self, "TrebbieAttack")

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
		character.take_damage(get_multiplied_atk())
		hero.gain_health(get_multiplied_atk() * hero.char_stats.hsg)
	if character is BaseHero:
		character.gain_health(hero.tip_heal_amount)


# This func is used for auto_attack, dont change this.
func use_ability():
	if is_on_cd: return
	super()

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade():
	super()

func set_ability_to_hero_stats() -> void:
	a_stats.aoe = hero.char_stats.aoe
	scale = a_stats.aoe * Vector2.ONE
	a_stats.atk = initial_dmg * hero.char_stats.atk/100
	
