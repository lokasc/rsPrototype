class_name BassheartAttack
extends BaseAbility

@export_category("Game stats")
@export var initial_cd : int = 2

@export_subgroup("Tech")
@export var hitbox_time_active : float = 0.1
@export var distance_to_center : float = 0

@onready var hitbox : Area2D = $AttackHitBox
@onready var hitbox_timer : Timer = $HitboxReset
@onready var weapon_sprite : Node2D = $"../Sprites/RotatingWeapon"
@onready var leg_sprite : AnimatedSprite2D = $"../Sprites/LegSprite2D"
@onready var effect_sprite : AnimatedSprite2D = $"../Sprites/RotatingWeapon/EffectSprite2D"


# Initialize abilities
# WARNING: export variables wont be avaliable on init, use enter_tree
func _init() -> void:
	super()

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree() -> void:
	pass

func _ready() -> void:
	hitbox.position.x = distance_to_center
	initial_effect_scale = effect_sprite.scale
	hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b")
	
	# connect signals
	hitbox.area_entered.connect(on_hit)
	hitbox_timer.timeout.connect(_hitbox_reset)

# Use statemachine logic if ability requires it
# use variable HERO to access hero's variables and functions
# Emit state_change(self, "new state name") to change out of state. 
func enter() -> void:
	hitbox.visible = true
	set_ability_to_hero_stats()

# normal attacks dont super() exit
func exit() -> void:
	hitbox.visible = false

# Automatically attack.
func update(_delta: float) -> void:
	if hero.input.is_use_mouse_auto_attack:
		look_at(hero.input.get_mouse_position())
		weapon_sprite.look_at(hero.input.get_mouse_position())
	set_ability_to_hero_stats()
	use_ability()

func physics_update(_delta: float) -> void:
	if hero.input.direction:
		hero.velocity = hero.input.direction * hero.char_stats.spd
		leg_sprite.play("walk")
	else:
		hero.velocity = hero.velocity.move_toward(Vector2.ZERO, hero.DECELERATION)
		leg_sprite.play("default")
	hero.move_and_slide()

# TODO: Clean this up
func _process(delta) -> void:
	super(delta)
	
	# calculating ability cooldown
	var ability_1_cd_display : int = int(hero.ability_1.a_stats.cd - hero.ability_1.current_time)
	var ability_2_cd_display : int = int(hero.ability_2.a_stats.cd - hero.ability_2.current_time)
	
	# Process abilities
	if hero.input.ability_1 and hero.ability_1.is_ready():
		if hero.input.is_on_beat: #Entering buff state while in sync
			hero.ability_1.is_synced = true
		state_change.emit(self, "BassheartFreeze")
	elif hero.input.ability_1: 
		print("Ability 1 is on cooldown! ", ability_1_cd_display)
	elif hero.input.ability_2 and hero.ability_2.is_ready():
		if hero.input.is_on_beat: #Entering buff state while in sync
			hero.ability_2.is_synced = true
		state_change.emit(self, "BassheartJump")
	elif hero.input.ability_2:
		print("Ability 2 is on cooldown! ", ability_2_cd_display)

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var enemy = area.get_parent() as BaseEnemy
	if enemy == null: return
	
	enemy.hit.connect(lifesteal)
	enemy.take_damage(get_multiplied_atk())
	enemy.hit.disconnect(lifesteal)

func _hitbox_reset() -> void:
	hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b") 

# This func is used for auto_attack, dont change this.
func use_ability() -> void:
	if is_on_cd: return
	super()
	if hero.animator.has_animation("attack"):
		hero.animator.play("attack")
		effect_sprite.show()
		#Changing the effect sprite size due to hero stats
		effect_sprite.scale = hero.char_stats.aoe * initial_effect_scale
		effect_sprite.play("attack_effect")
	hitbox.monitoring = true
	hitbox.get_child(0).debug_color = Color("dd488d6b")
	hitbox_timer.start(hitbox_time_active)

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade() -> void:
	super()

# The attack will be dependent on the hero stats
func set_ability_to_hero_stats() -> void:
	a_stats.aoe = hero.char_stats.aoe ; scale = a_stats.aoe * Vector2.ONE
	a_stats.atk = hero.char_stats.atk
	a_stats.cd = initial_cd * hero.char_stats.cd

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if hero.animator.has_animation("idle"):
		hero.animator.play("idle")
		effect_sprite.hide()
