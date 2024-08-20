class_name BassheartAttack
extends BaseAbility

@export_category("Game stats")
@export var initial_dmg = 100
@export var initial_cd = 2

@export_subgroup("Tech")
@export var hitbox_time_active : float = 0.1
@export var distance_to_center : float = 0

@onready var hitbox : Area2D = $AttackHitBox
@onready var hitbox_timer : Timer = $HitboxReset

# Initialize abilities
# WARNING: export variables wont be avaliable on init, use enter_tree
func _init():
	super()

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree():
	a_stats.cd = initial_cd
	a_stats.atk = initial_dmg

func _ready() -> void:
	hitbox.position.x = distance_to_center
	hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b")
	
	# connect signals
	hitbox.area_entered.connect(on_hit)
	hitbox_timer.timeout.connect(_hitbox_reset)

# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func enter():
	super()
	hitbox.visible = true

func exit():
	super() # starts cd here.
	hitbox.visible = false

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
	var ability_1_cd_display = int(hero.ability_1.a_stats.cd - hero.ability_1.current_time)
	if hero.input.ability_1:
		if hero.ability_1.is_ready():
			state_change.emit(self, "BassheartFreeze")
		else: print("Ability 1 is on cooldown! ", ability_1_cd_display)

func on_hit(area : Area2D):
	if !multiplayer.is_server(): return
	
	# typecasting
	var enemy = area.get_parent() as BaseEnemy
	if enemy == null: return
	
	#enemy.add_status("Bleed", [5,2,1])
	
	# TODO: not networked yet
	# need to calculate how much damage based on 
	# the attack value of this ability + my character's attack value
	enemy.take_damage(initial_dmg)

func _hitbox_reset():
	hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b") 
	if hero.animator.has_animation("idle"):
		hero.animator.play("idle")

# This func is used for auto_attack, dont change this.
func use_ability():
	if is_on_cd: return
	super()
	if hero.animator.has_animation("attack"):
		hero.animator.play("attack")
	hitbox.monitoring = true
	hitbox.get_child(0).debug_color = Color("dd488d6b")
	hitbox_timer.start(hitbox_time_active)

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade():
	super()

# Called automatically when ability cd finishes, override this to addd functionality when cd finishes
func _on_cd_finish():
	super()

# Resets ability, lets players to use it again, override this to add functionality.
func _reset():
	super()
