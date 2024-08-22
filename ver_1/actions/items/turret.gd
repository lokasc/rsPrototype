class_name Turret
extends BaseItem

@export var turret_duration : float
@export var turret_range : int
@export var deploy_time : float
@export var damage_per_tick : int = 1
@export var initial_tick_time : float = 0.5

var enemies_in_hitbox : Array[BaseEnemy] = []
var current_time : float

@onready var hitbox : Area2D = $HitBox
@onready var hitbox_shape : CollisionShape2D = $HitBox/CollisionShape2D
@onready var hit_itmer : Timer = $HitTimer

func _init() -> void:
	pass

func _enter_tree() -> void:
	super()
	current_time = 0
	a_stats.atk = damage_per_tick
	a_stats.cd = initial_tick_time

func _ready() -> void:
	# Detect only enemies, sanity check.
	hitbox.set_collision_mask_value(3, true)
	hitbox_shape.shape.radius = turret_range
	deploy_time = 0
	
	hitbox.area_entered.connect(_on_hit_box_area_entered)
	hitbox.area_exited.connect(_on_hit_box_area_exited)
	
func _update(delta) -> void:
	current_time += delta
	deploy_time += delta
	if current_time >= a_stats.cd:
		current_time = 0
		aoe_dmg()
	if deploy_time >= turret_duration:
		queue_free()

func aoe_dmg() -> void:
	if !multiplayer.is_server(): return
	hit_itmer.start(0.1)
	hitbox_shape.debug_color = Color("dd488d6b")
	for enemy : BaseEnemy in enemies_in_hitbox:
		enemy.take_damage(a_stats.get_total_dmg())

func _on_hit_box_area_entered(area: Area2D) -> void:
	var enemy : BaseEnemy = area.get_parent() as BaseEnemy
	if !enemy: return
	
	enemies_in_hitbox.append(enemy)

func _on_hit_box_area_exited(area: Area2D) -> void:
	var enemy : BaseEnemy = area.get_parent() as BaseEnemy
	if !enemy: return
	
	# might get too computationally heavy
	if enemies_in_hitbox.has(enemy):
		enemies_in_hitbox.erase(enemy)

func _on_hit_timer_timeout() -> void:
	hitbox_shape.debug_color = Color("0099b36b")
