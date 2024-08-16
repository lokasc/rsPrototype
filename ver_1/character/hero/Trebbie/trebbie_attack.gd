class_name TrebbieAttack
extends BaseAbility

@export_category("Game stats")
@export var initial_dmg = 100
@export var initial_cd = 2

@export_subgroup("Tech")
@export var hitbox_time_active : float = 0.1
@export var distance_to_center : float = 2000

@onready var hitbox : Area2D = $AttackHitBox
@onready var hitbox_timer : Timer = $HitboxReset


func _init():
	super()

func _enter_tree():
	a_stats.cd = initial_cd
	a_stats.atk = initial_dmg

func _ready():
	hitbox.position.x = distance_to_center
	hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b")
	
	# connect signals
	hitbox.area_entered.connect(on_hit)
	hitbox_timer.timeout.connect(_hitbox_reset)

func _process(delta):
	super(delta)

func on_hit(area : Area2D):
	if !multiplayer.is_server() : return
	
	# typecasting
	var enemy = area.get_parent() as BaseEnemy
	if enemy == null: return
	
	# TODO: not networked yet
	# need to calculate how much damage based on 
	# the attack value of this ability + my character's attack value
	enemy.take_damage(initial_dmg)

func use_ability():
	if is_on_cd: return
	super()
	
	hitbox.monitoring = true
	hitbox.get_child(0).debug_color = Color("dd488d6b")
	hitbox_timer.start(hitbox_time_active)

func _hitbox_reset():
	hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b") 

func _reset():
	super()

# Override virtual func to change what happens on cooldown finish
func _on_cd_finish():
	super()

# Trebbie's attack dmg is upgraded and cooldown is reduced.
func _upgrade():
	super()
	pass