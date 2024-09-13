class_name AOEItem
extends BaseItem

@export var damage_per_tick : int
@export var initial_tick_time : float
@export var area_of_effect : int

@export_category("Ascended")
@export var heal_amount : float

var enemies_in_hitbox : Array[BaseEnemy] = []
var current_time : float

var hitbox_shape : CollisionShape2D

func _init() -> void:
	action_name = "Melodic Field"
	card_desc = "A music field damages nearby enemies.\n[AoE][Cooldown]"
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
		if is_ascended:
			if not enemy.die.is_connected(ascended_ability):
				enemy.die.connect(ascended_ability)
		enemy.take_damage(a_stats.get_total_dmg())
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
	a_stats.atk = damage_per_tick * hero.char_stats.maxhp/100
	a_stats.cd = initial_tick_time * hero.char_stats.cd
	a_stats.aoe = area_of_effect * hero.char_stats.aoe 
	hitbox_shape.shape.radius = a_stats.aoe
	
	desc = "Damages nearby enemies by " + change_text_color(str(snapped(a_stats.atk,0.01)),"red") + " every " + change_text_color(str(snapped(a_stats.cd,0.01)),"red") + " seconds."

func ascended_ability():
	hero.gain_health(heal_amount)
