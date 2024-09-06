class_name BaseEnemy
extends BaseCharacter

signal hit(dmg) # hit by enemy

# For inspector view only, cant modify class stats in inspector. 
@export_category("Basic information")
@export var max_health : float
@export var speed : int
@export var dmg : float

@export_subgroup("Status")
@export var can_move : bool
@export var frozen : bool

# XP & Loot
@export_subgroup("XP")
@export var xp_worth : int = 1
@export var xp_drop_spread : int
@onready var loot : Node = get_tree().get_first_node_in_group("loot")
@onready var xp_orb : Resource = load("res://ver_1/game/spawn_system/experience_orbs.tscn")

var target : BaseHero
var sprite
var x_scale : int

## Base class for all enemy types.
## Has a position and health.

func _init() -> void:
	super()

func _init_stats() -> void:
	char_stats.maxhp = max_health
	char_stats.spd = speed
	char_stats.atk = dmg
	current_health = char_stats.maxhp
	
	can_move = true
	frozen = false
	pass

# Export variables arent ready on innit
func _enter_tree() -> void:
	target = get_closest_target_position()
	_init_stats()

func take_damage(p_dmg:float) -> void:
	# Client prediction
	if current_health - p_dmg <= 0:
		death.rpc()
		p_dmg = current_health
	else:
		current_health -= p_dmg
	hit.emit(p_dmg)
	
	# dmg visual is actually how much u've dealt to remaining health
	# not the raw power.
	GameManager.Instance.vfx.spawn_pop_up(p_dmg, global_position)

@rpc("unreliable_ordered", "call_local")
func death() -> void:
	for i in range(xp_worth):
		var new_xp = xp_orb.instantiate()
		loot.call_deferred("add_child", new_xp)
		new_xp.position = position + Vector2(randi_range(-xp_drop_spread,xp_drop_spread),randi_range(-xp_drop_spread,xp_drop_spread))
	queue_free()

func move_to_target(p_target = null) -> void:
	if p_target == null: return

# direction need to go towards
	var direction : Vector2 = global_position.direction_to(p_target.global_position)
	var distance : float = global_position.distance_to(p_target.global_position)
	
	if distance < 15:
		velocity = Vector2.ZERO
	else:
		velocity = direction * char_stats.spd
	
	if direction.x < 0:
		sprite.scale.x = x_scale
	elif direction.x > 0:
		sprite.scale.x = x_scale * -1
	else:
		sprite.scale.x = x_scale * -1
	move_and_slide()

func get_closest_target_position() -> BaseHero:
	var closest_hero : BaseHero = null 
	var closest_magnitude : float = 9999999
	for x in GameManager.Instance.players:
		if x.global_position.distance_to(self.global_position) < closest_magnitude:
			closest_hero = x
			closest_magnitude = x.global_position.distance_to(self.global_position)
	return closest_hero
