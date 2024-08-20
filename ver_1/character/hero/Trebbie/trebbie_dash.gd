# meta-description: Skeleton for creating abilities, handles cooldowns & upgrading logic, shows all virtual functions. 
class_name TrebbieDash
extends BaseAbility

@export_category("Game stats")
@export var initial_dmg : int
@export var initial_cd : int
@export var zero_cd : bool = false
@export var speed : int
@export var distance : int

var original_pos = Vector2.ZERO
var direction = Vector2.ZERO

@onready var hitbox : Area2D = $HitBox
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
	if zero_cd:
		a_stats.cd = 0

func enter():
	super()
	# Store hero position and the direction when the ability is used
	original_pos = hero.position
	
	look_at(hero.input.get_mouse_position())
	direction = original_pos.direction_to(hero.input.get_mouse_position())
	
	# enable hitboxes
	collisionbox.disabled = false
	collisionbox.visible = true
	hitbox.monitoring = true
	hitbox.visible = true

func exit():
	super() # starts cd here.
	start_cd()
	# disable hitboxes
	collisionbox.disabled = true
	collisionbox.visible = false
	hitbox.visible = false
	hitbox.monitoring = false
	
func update(_delta: float):
	super(_delta)
	pass

func physics_update(_delta: float):
	super(_delta)
	# Ability movement
	var new_position = original_pos + direction * distance
	hero.position = hero.position.move_toward(new_position, speed)
	if hero.position == new_position:
		state_change.emit(self, "TrebbieAttack")

func _process(delta):
	super(delta)
	pass
	
func on_hit(area : Area2D):
	if !multiplayer.is_server(): return
	
	# typecasting
	var enemy = area.get_parent() as BaseEnemy
	if enemy == null: return
	
	# TODO: not networked yet
	# need to calculate how much damage based on 
	# the attack value of this ability + my character's attack value
	enemy.take_damage(initial_dmg)
	hero.gain_health(initial_dmg*hero.char_stats.hsg)

# This func is used for auto_attack, dont change this.
func use_ability():
	if is_on_cd: return
	super()

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade():
	super()

# Called automatically when ability cd finishes, override this to addd functionality when cd finishes
func _on_cd_finish():
	_reset()

# Resets ability, lets players to use it again, override this to add functionality.
func _reset():
	super()
