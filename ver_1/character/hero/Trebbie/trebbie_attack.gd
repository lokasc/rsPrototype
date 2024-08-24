class_name TrebbieAttack
extends BaseAbility

@export_category("Game stats")
@export var initial_dmg : int
@export var initial_cd : int = 2

@export_subgroup("Tech")
@export var hitbox_time_active : float = 0.1
@export var distance_to_center : float
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

func enter():
	hitbox.visible = true
	pass

func exit():
	hitbox.visible = false
	pass

# Automatically attack.
func update(_delta: float):
	if hero.input.is_use_mouse_auto_attack:
		look_at(hero.input.get_mouse_position())
	use_ability()
	

func physics_update(_delta: float):
	if hero.input.direction:
		hero.velocity = hero.input.direction * hero.char_stats.spd
	else:
		hero.velocity = hero.velocity.move_toward(Vector2.ZERO, hero.DECELERATION)
	hero.move_and_slide()

# TODO: Clean this up
func _process(delta):
	super(delta)
	
	# calculating ability cooldown
	var ability_1_cd_display = int(hero.ability_1.a_stats.cd - hero.ability_1.current_time)
	var ability_2_cd_display = int(hero.ability_2.a_stats.cd - hero.ability_2.current_time)
	
	
	# Process abilities
	if hero.input.ability_1 and hero.ability_1.is_ready():
		state_change.emit(self, "TrebbieBuff")
	elif hero.input.ability_1: 
		print("Ability 1 is on cooldown! ", ability_1_cd_display)
	elif hero.input.ability_2 and hero.ability_2.is_ready():
		state_change.emit(self, "TrebbieDash")
	elif hero.input.ability_2:
		print("Ability 2 is on cooldown! ", ability_2_cd_display)

func on_hit(area : Area2D):
	if !multiplayer.is_server(): return
	
	# Find enemy, deal dmg.
	var enemy = area.get_parent() as BaseEnemy
	if enemy == null: return

	enemy.take_damage(get_multiplied_atk())
	
	# TODO: have to change how lifesteal works, 
	# not relating it to the atk stat but the damage enemies receive
	hero.gain_health(get_multiplied_atk() * hero.char_stats.hsg)
	
func use_ability():
	if is_on_cd: return
	super()

	if hero.animator.has_animation("attack"):
		hero.animator.play("attack")
	
	hitbox.monitoring = true
	hitbox.get_child(0).debug_color = Color("dd488d6b")
	hitbox_timer.start(hitbox_time_active)

func _hitbox_reset():
	hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b") 
	
	if hero.animator.has_animation("idle"):
		hero.animator.play("idle")

func _reset():
	super()

# Override virtual func to change what happens on cooldown finish
func _on_cd_finish():
	super()

# Trebbie's attack dmg is upgraded and cooldown is reduced.
func _upgrade():
	super()
	pass
