class_name Turret
extends Node2D

signal destroy_turret(turret)

# all defined by the turret item
@export var turret_duration : float
@export var turret_range : float
@export var deploy_time : float
@export var damage_per_tick : float = 1
@export var initial_tick_time : float = 0.5
@export var knockback_distance : int = 0

var is_ascended : bool = false

@onready var hitbox : Area2D = $HitBox
@onready var hitbox_shape : CollisionShape2D = $HitBox/CollisionShape2D
@onready var hit_timer : Timer = $HitTimer
var item : BaseItem 

var enemies_in_hitbox : Array[BaseEnemy] = []
var current_time : float

func _enter_tree() -> void:
	current_time = 0
	deploy_time = 0

func _ready() -> void:
	hitbox.set_collision_mask_value(3, true)
	hitbox_shape.shape.radius = turret_range
	hitbox.monitoring = true
	hitbox.area_entered.connect(_on_hit_box_area_entered)
	hitbox.area_exited.connect(_on_hit_box_area_exited)

func _update(delta) -> void:
	current_time += delta
	deploy_time += delta
	if current_time >= initial_tick_time:
		deal_damage()
		current_time = 0
	if deploy_time >= turret_duration:
		destroy_turret.emit(self)

func deal_damage() -> void:
	if !multiplayer.is_server(): return
	hit_timer.start(0.1)
	hitbox_shape.debug_color = Color("dd488d6b")
	
	for enemy : BaseEnemy in enemies_in_hitbox:
		enemy.take_damage(item.a_stats.get_total_dmg())
		if is_ascended:
			enemy.add_status("Knockback", [knockback_distance,position,1])

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
