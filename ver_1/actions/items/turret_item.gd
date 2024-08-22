class_name TurretItem
extends BaseItem

@export_category("Deploying stats")
@export var deploy_range : int
@export var deploy_tick_time : float
@export var deploy_amount : int

@export_category("Turret stats")
@export var damage_per_tick : int
@export var damage_tick_time : float
@export var turret_range : int
@export var turret_duration : float

var enemies_in_hitbox : Array[BaseEnemy] = []
var current_time : float
var current_turret_time : float

@onready var turret = load("res://ver_1/actions/items/turret.tscn")
@onready var all_turrets : Node = $Turrets

func _init() -> void:
	action_name = "Buildin a Sentry!"
	desc = "No spies be sappin' my sentry now"

func _enter_tree() -> void:
	super()
	current_time = 0
	a_stats.atk = damage_per_tick
	a_stats.cd = deploy_tick_time

func _ready() -> void:
	pass

func _update(delta) -> void:
	global_position = hero.global_position
	current_time += delta
	if current_time >= a_stats.cd:
		for i in range(deploy_amount):
			spawn_turret()
		current_time = 0

func aoe_dmg() -> void:
	if !multiplayer.is_server(): return
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

@rpc("unreliable_ordered", "call_local")
func spawn_turret():
	var new_turret : Turret = turret.instantiate()
	var rand_pos = Vector2(randi_range(-deploy_range,deploy_range),randi_range(-deploy_range,deploy_range))
	
	new_turret.damage_per_tick = damage_per_tick
	new_turret.initial_tick_time = damage_tick_time
	new_turret.damage_per_tick = damage_per_tick
	new_turret.turret_duration = turret_duration
	new_turret.turret_range = turret_range
	
	all_turrets.call_deferred("add_child", new_turret)
	new_turret.position = position + rand_pos
