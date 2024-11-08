class_name TrebbieAttack
extends BaseAbility

@export_category("Game stats")
@export var initial_cd : float = 2

@export_subgroup("Tech")
@export var hitbox_time_active : float = 0.1
@export var distance_to_center : float
@export var tip_dmg_multiplier : float

var ability_1_cd_display : int
var ability_2_cd_display : int
var has_attacked : bool = false
var already_hit : Array[BaseEnemy] = []

@onready var hitbox : Area2D = $AttackHitBox
@onready var hitbox_timer : Timer = $HitboxReset
@onready var tip_hitbox : Area2D = $TipHitBox

@onready var weapon_sprite : Node2D = $"../Sprites/RotatingWeapon"
@onready var leg_sprite : AnimatedSprite2D = $"../Sprites/LegSprite2D"
@onready var effect_sprite : AnimatedSprite2D = $"../Sprites/RotatingWeapon/EffectSprite2D"



func _init() -> void:
	super()

func _enter_tree() -> void:
	pass

func _ready() -> void:
	super()
	effect_sprite.visible = false
	hitbox.position.x = distance_to_center
	initial_effect_scale = effect_sprite.scale
	hitbox.monitoring = false
	tip_hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b")
	

func enter() -> void:
	hitbox.visible = true
	tip_hitbox.visible = true
	set_ability_to_hero_stats()
	
	# TODO: Emit an rpc that we are in this new state.
	pass

func exit() -> void:
	hitbox.visible = false
	tip_hitbox.visible = false
	_reset()

# Automatically attack.
func update(_delta: float) -> void:
	if hero.input.is_use_mouse_auto_attack:
		look_at(hero.input.get_mouse_position())
		weapon_sprite.look_at(hero.input.get_mouse_position())
	#Setting ability stats to hero stats
	set_ability_to_hero_stats()
	if beat_count == 1:
		if not has_attacked:
			use_basic_attack()
			has_attacked = true
	else: has_attacked = false
	
	# Process abilities
	if hero.input.ability_1:
		if hero.ability_1.is_ready():
			if hero.input.is_on_beat: #Entering buff state while in sync
				hero.ability_1.is_synced = true
			state_change.emit(self, "TrebbieBuff")
		else: print("Ability 1 is on cooldown! ", ability_1_cd_display)
	elif hero.input.ability_2:
		if hero.ability_2.is_ready():
			if hero.input.is_on_beat: #Entering buff state while in sync
				hero.ability_2.is_synced = true
			state_change.emit(self, "TrebbieDash")
		else: print("Ability 2 is on cooldown! ", ability_2_cd_display)
	hero.input.ability_1 = false
	hero.input.ability_2 = false

func physics_update(_delta: float) -> void:
	if hero.input.direction:
		hero.velocity = hero.input.direction * hero.char_stats.spd
		leg_sprite.play("walk")
	else:
		hero.velocity = hero.velocity.move_toward(Vector2.ZERO, hero.DECELERATION)
		leg_sprite.play("default")
	hero.move_and_slide()

# TODO: Clean this up
func _process(delta : float) -> void:
	super(delta)
	
	# calculating ability cooldown
	ability_1_cd_display = int(hero.ability_1.a_stats.cd - hero.ability_1.current_time)
	ability_2_cd_display = int(hero.ability_2.a_stats.cd - hero.ability_2.current_time)

func _on_tip_hit(area: Area2D) -> void:
	var character : BaseCharacter = null 
	if area.get_parent() is BaseCharacter:
		character = area.get_parent()

	# do not execute on non-characters or nulls
	if !character && !(character is BaseCharacter): return

	if character is BaseEnemy:
		already_hit.append(character)
		#print(character)
		#print("tipper: " + str(area.get_parent()))
		character.hit.connect(lifesteal)
		character.take_damage(get_multiplied_atk() * tip_dmg_multiplier)
		character.hit.disconnect(lifesteal)
	if character is BaseHero:
		if !multiplayer.is_server(): return
		character.gain_health(hero.tip_heal_amount)

func on_hit(area : Area2D) -> void:
	# Find enemy, deal dmg.
	var enemy = area.get_parent() as BaseEnemy
	if enemy == null: return
	
	# check if we already hit the enemy with the tiper.
	if enemy in already_hit: return
	#print("regular: " + str(area.get_parent()))
	
	enemy.hit.connect(lifesteal) # The tip and normal hitbox are mutually exclusive
	enemy.take_damage(get_multiplied_atk())
	enemy.hit.disconnect(lifesteal)

func use_basic_attack() -> void:
	if is_on_cd: return
	effect_sprite.visible = true
	super()
	# Reset already hit targets.
	already_hit.clear()
	
	if hero.animator.has_animation("attack"):
		hero.animator.play("attack")
		effect_sprite.show()
		#Changing the effect sprite size due to hero stats
		effect_sprite.scale = hero.char_stats.aoe * initial_effect_scale
		effect_sprite.play("attack_effect")
		
	tip_hitbox.monitoring = true
	hitbox.monitoring = true
	hitbox.get_child(0).debug_color = Color("dd488d6b")
	tip_hitbox.get_child(0).debug_color = Color("dd488d6b")
	hitbox_timer.start(hitbox_time_active)

func _hitbox_reset() -> void:
	hitbox.monitoring = false
	tip_hitbox.monitoring = false
	hitbox.get_child(0).debug_color = Color("0099b36b") 
	tip_hitbox.get_child(0).debug_color = Color("af4aff6b")

# The attack will be dependent on the hero stats
func set_ability_to_hero_stats() -> void:
	a_stats.aoe = hero.char_stats.aoe ; scale = a_stats.aoe * Vector2.ONE
	a_stats.atk = hero.char_stats.atk
	a_stats.cd = initial_cd * hero.char_stats.cd

# Trebbie's attack dmg is upgraded and cooldown is reduced.
func _upgrade() -> void:
	super()
	pass

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if hero.animator.has_animation("idle"):
		hero.animator.play("idle")
		effect_sprite.hide()
