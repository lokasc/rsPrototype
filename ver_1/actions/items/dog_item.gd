class_name DogItem
extends BaseItem

# dog (snowy) [Stat Dependancy: Not Sure Yet] 
# when a movement ability is used, it charges with you in a duet attack.
# when asc: at the end of a charge, snowy flings his tail in an aoe
# freezing all enemies hit by his tail.

@export var dog_dmg : float = 10
@export var charge_spd : float = 1
@export var follow_spd : float = 5
@export var charge_extra_dist = 100

@export_subgroup("references")
@export var sprite : Sprite2D
@export var hitbox : Area2D

# Sprite rotation
var new_position : Vector2
var is_left : bool

# dog charge
var is_charging : bool = false:
	set(value):
		is_charging = value
		hitbox.monitoring = is_charging

var charge_pos : Vector2 = Vector2.ZERO

func _init() -> void:
	action_icon_path = "res://assets/icons/dog_icon.png"
	action_name = "DAW.G"
	card_desc = "NB: G means good boy v2"
	pass

# Connect any signals from the hero here.
func _enter_tree() -> void:
	super()
	# all movement abilities are on ability2.
	hero.ability_2.ability_used.connect(on_movement_ability_used)

func _ready() -> void:
	position = hero.position + Vector2(50, 50)
	is_charging = false

# Update is called by the main character
func _update(_delta:float) -> void:
	super(_delta)
	
	if is_charging:
		new_position = position.move_toward(charge_pos, charge_spd)
		set_sprite_direction()
		position = new_position
		if position == charge_pos:
			is_charging = false
	else:
		$Sprite.material.set_shader_parameter("flash_speed", 0)
		new_position = position.move_toward(hero.position + Vector2(15, 15), follow_spd)
		set_sprite_direction()
		position = new_position

func set_sprite_direction():
	# world space to camera space
	var new_pos_from_old_pos = new_position - position
	
	if new_pos_from_old_pos.x < 0:
		if is_left == false:
			is_left = !is_left
			sprite.scale.x *= -1
	else:
		if is_left == true:
			is_left = !is_left
			sprite.scale.x *= -1

func _upgrade() -> void:
	super()

func on_movement_ability_used() -> void:
	$Sprite.material.set_shader_parameter("flash_speed", 6)
	charge_pos = hero.ability_2.new_position + position.direction_to(hero.ability_2.new_position) * charge_extra_dist
	is_charging = true

func _on_area_2d_area_entered(area: Area2D) -> void:
	var enemy : BaseEnemy = area.get_parent() as BaseEnemy
	if !enemy: return
	
	enemy.take_damage(a_stats.atk)

func set_item_stats() -> void:
	a_stats.atk = dog_dmg * hero.get_atk()/hero.initial_damage
