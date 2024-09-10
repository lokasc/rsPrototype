class_name AOEItem
extends BaseItem

@export var damage_per_tick : int
@export var initial_tick_time : float
@export var area_of_effect : int

@export_category("Ascended")
@export var shield_amount : float
@export var shield_duration : float

var enemies_in_hitbox : Array[BaseEnemy] = []
var current_time : float

var hitbox_shape : CollisionShape2D

func _init() -> void:
	action_name = "AOE_dmg"
	desc = "Power of friendship!"
	action_icon_path = "res://assets/icons/aoe_icon.png"

func _enter_tree() -> void:
	super()
	current_time = 0

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
		if is_ascended:
			if enemy.die:
				hero.gain_shield(shield_amount, shield_duration)

func _upgrade() -> void:
	super()
	damage_per_tick += 5
	area_of_effect += 2
	set_item_stats()
	
func _ready() -> void:
	hitbox_shape = get_child(0).get_child(0)
	
	# Shapes in CollisionShape Class are resources: Dupe and reassign
	hitbox_shape.shape = hitbox_shape.shape.duplicate()
	set_item_stats()
	
	# only detect enemies, sanity check
	hitbox_shape.get_parent().set_collision_mask_value(3, true)
	
	#hitbox_shape.debug_color = Color.WEB_GREEN
	
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
	a_stats.atk = damage_per_tick * hero.get_atk()/hero.initial_damage
	a_stats.cd = initial_tick_time * hero.char_stats.cd
	a_stats.aoe = area_of_effect * hero.char_stats.aoe 
	hitbox_shape.shape.radius = a_stats.aoe

func check_kills_enemy(_enemy : BaseEnemy) -> bool:
	if _enemy.current_health - a_stats.get_total_dmg() <= 0:
		return true
	else: return false
