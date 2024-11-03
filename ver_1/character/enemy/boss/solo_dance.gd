class_name DuoDance
extends BossAbility

# The boss will target one player's box and randomly be at one of four sides
# The boss will shoot projectiles in a direction towards the player.

# Side is given by an int where:
# LEFT = 0, RIGHT = 1, TOP = 2, BOTTOM = 3

@export var is_biano : bool = false
@export var change_side_time : float = 16 # How long in seconds until you change sides?

@export_group("Projectile settings")
@export var p_dmg : float
@export var p_spd : float
@export var projectile_scale : Vector2
@export var projectile_scene : PackedScene = preload("res://ver_1/character/enemy/boss/B&B/bnb_projectile.tscn")

var current_side = 0
var prev_side = -1
var target : BaseHero
var rng = RandomNumberGenerator.new()

func enter() -> void:
	super()
	select_target()
	decide_side()
	teleport_to_side()

func exit() -> void:
	super()
	$SideChangeTimer.stop()

func update(delta) -> void:
	pass

func physics_update(delta) -> void:
	super(delta)

func spawn_projectile(gpos : Vector2, direction : Vector2) -> void:
	var copy = projectile_scene.instantiate()
	
	copy.dmg = p_dmg
	copy.spd = p_spd
	copy.tile_scale = projectile_scale
	
	copy.initial_boss_atk = boss.initial_atk
	copy.boss_atk = boss.char_stats.atk
	
	copy.global_position = gpos
	
	#copy.look_at(target.global_position)
	#copy.rotate(deg_to_rad(270))
	
	GameManager.Instance.net.spawnable_path.call_deferred("add_child", copy, true)
	# spawn in network node.

func select_target():
	if is_biano: target = GameManager.Instance.get_player(1)
	else: 
		for x in GameManager.Instance.players:
			if x.player_id == 1: return
			target = x

func decide_side():
	if !multiplayer.is_server(): return
	while true:
		current_side = rng.randi_range(0, 3)
		if prev_side != current_side:
			break

# Teleport to a position based on the current side.
func teleport_to_side():
	var tp_pos = Vector2(0,0)
	match current_side:
		0:
			if is_biano: tp_pos = Vector2(-400, 0)
			else: tp_pos = Vector2(400, 0)
		1:
			tp_pos = Vector2(0,0)
		2:
			if is_biano: tp_pos = Vector2(-200, -200)
			else: tp_pos = Vector2(200, -200)
		3:
			if is_biano: tp_pos = Vector2(-200, 200)
			else: tp_pos = Vector2(200, 200)
	
	global_position = tp_pos
	$SideChangeTimer.start(change_side_time)

func _on_side_change_timer_timeout() -> void:
	decide_side()
	teleport_to_side()
