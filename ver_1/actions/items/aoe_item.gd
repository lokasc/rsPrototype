class_name AOEItem
extends BaseItem

@export var damage_per_tick : int
@export var initial_tick_time : float
@export var area_of_effect : int

var enemies_in_hitbox : Array[BaseEnemy] = []
var current_time : float

@onready var hitbox_shape : CollisionShape2D = $HitBox/CollisionShape2D

func _init() -> void:
	action_name = "AOE_dmg"
	desc = "Power of friendship!"
	action_icon_path = "res://assets/icons/dust-cloud.png"

func _enter_tree() -> void:
	super()
	current_time = 0
	a_stats.atk = damage_per_tick
	a_stats.cd = initial_tick_time

func _update(_delta:float) -> void:
	global_position = hero.global_position
	current_time += _delta
	if current_time >= a_stats.cd:
		current_time = 0
		aoe_dmg()

func aoe_dmg() -> void:
	if !multiplayer.is_server(): return
	for enemy : BaseEnemy in enemies_in_hitbox:
		enemy.take_damage(a_stats.get_total_dmg())

func _upgrade() -> void:
	super()
	damage_per_tick += 5
	area_of_effect += 2
	set_item_stats()
func _ready() -> void:
	# Detect only enemies, sanity check.
	$HitBox.set_collision_mask_value(3, true)
	hitbox_shape.shape.radius = area_of_effect

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

func set_item_stats():
	a_stats.atk = damage_per_tick
	a_stats.cd = initial_tick_time
	hitbox_shape.shape.radius = area_of_effect
	
