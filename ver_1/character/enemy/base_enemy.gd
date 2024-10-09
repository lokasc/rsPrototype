class_name BaseEnemy
extends BaseCharacter

signal hit(dmg) # hit by enemy
signal die # enemy dies here.
signal status_applied # When a new status is applied.

# For inspector view only, cant modify class stats in inspector. 
@export_category("Basic information")
@export var max_health : float
@export var speed : int
@export var dmg : float

@export_subgroup("Pathfinding")
@export var path_update_period : float = 1.0
@export var path_update_rand_offset : float = 1.0
@export var use_pathfinding : bool = false
@export var nav : NavigationAgent2D

@export_subgroup("Status")
@export var can_move : bool
@export var frozen : bool

# XP & Loot
@export_subgroup("XP")
@export var xp_worth : int = 1
@export var xp_drop_spread : int
@onready var loot : Node = get_tree().get_first_node_in_group("loot")
@onready var xp_orb : Resource = load("res://ver_1/game/spawn_system/experience_orbs.tscn")

var next_path_position : Vector2
var current_agent_position : Vector2
var path_wait_time : float = 0
var prev_target_pos : Vector2

var move_towards_threshold = 15
var target : BaseHero
var sprite
var x_scale : int

@export_subgroup("Optimization")
@export var update_frequency : float = 3
var current_update_time : float = 0

@export_subgroup("Juice")
@export var flash_time : float = 0.15
var flash_current_time : float
var is_flashing : bool = false
var original_modulation : Color


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
	# assign random time, so enemies dont update all together
	if multiplayer.is_server():
		current_update_time = randf_range(0, update_frequency)

func _ready() -> void:
	super()
	hit.connect(flash_sprite)
	if use_pathfinding:
		call_deferred("path_find_set_up")
		target = get_closest_target_position()
		prev_target_pos = target.global_position

func take_damage(p_dmg:float) -> void:
	if current_health <= 0: return
	
	# calculate dmg dealt to remaining health
	var dmg_dealt = p_dmg
	if current_health - p_dmg <= 0:
		dmg_dealt = current_health
	
	if multiplayer.is_server():
		current_health -= p_dmg 
	
	hit.emit(p_dmg) # this is to signify that something has been hit.
	GameManager.Instance.vfx.spawn_pop_up(get_instance_id(), int(dmg_dealt), global_position)
	check_death()

func _process(delta: float) -> void:
	#print(str(multiplayer.is_server()) + " : " + str(current_health))
	process_get_enemy(delta)
	process_flash(delta)

func check_death():
	if !multiplayer.is_server(): return
	if current_health <= 0:
		death.rpc()

# unreliable_ordered as XP doesnt have to be exactly position synced.
@rpc("unreliable_ordered", "call_local")
func death() -> void:
	die.emit()
	for i in range(xp_worth):
		var new_xp = xp_orb.instantiate()
		loot.call_deferred("add_child", new_xp)
		new_xp.position = position + Vector2(randi_range(-xp_drop_spread,xp_drop_spread),randi_range(-xp_drop_spread,xp_drop_spread))
	delayed_death()

func delayed_death():
	visible = false
	if multiplayer.is_server():
		call_deferred("queue_free")

func move_to_target(p_target = null) -> void:
	if p_target == null: return

# direction need to go towards
	var direction : Vector2 = global_position.direction_to(p_target.global_position)
	var distance : float = global_position.distance_to(p_target.global_position)
	
	if distance < move_towards_threshold:
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
	for x : BaseHero in GameManager.Instance.players:
		if x.IS_DEAD: continue
		if x.global_position.distance_to(self.global_position) < closest_magnitude:
			closest_hero = x
			closest_magnitude = x.global_position.distance_to(self.global_position)
	return closest_hero

func on_end_game():
	set_process(false)
	set_physics_process(false)

func get_path_update_period() -> float:
	var offset = randf_range(0,path_update_rand_offset)
	return path_update_period + offset

func path_find_set_up() -> void:
	if nav == null: return
	await get_tree().physics_frame
	if target: nav.target_position = target.global_position

func set_path_position(_target : BaseCharacter = null) -> void:
	if nav == null or _target == null: return
	if nav.is_navigation_finished(): return
	nav.target_position = _target.global_position
	next_path_position = nav.get_next_path_position()
	current_agent_position = global_position
	prev_target_pos = target.global_position

func pathfind_to_target(_target : BaseCharacter, _delta : float):
	if path_wait_time >= get_path_update_period():
		if target.global_position != prev_target_pos:
			set_path_position(target)
			path_wait_time = 0
			prev_target_pos = target.global_position
	path_wait_time += _delta
	velocity = current_agent_position.direction_to(next_path_position) * char_stats.spd
	move_and_slide()

func flash_sprite(p_dmg):
	original_modulation = sprite.self_modulate
	sprite.self_modulate = Color(1,0,0)
	flash_current_time = flash_time
	is_flashing = true

func process_get_enemy(delta):
	current_update_time += delta
	
	if current_update_time >= update_frequency:
		target = get_closest_target_position()
		current_update_time = 0

# Counts down to 0, when it does modulates sprite back to normal.
func process_flash(delta):
	# Stop timer activity when countdown finishes.
	if is_flashing:
		flash_current_time -= delta
		if flash_current_time <= 0:
			sprite.self_modulate = original_modulation
			is_flashing = false
