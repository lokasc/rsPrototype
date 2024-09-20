class_name DogItem
extends BaseItem

# dog (snowy) [Stat Dependancy: Not Sure Yet] 
# attacks single targets and inflicts freeze.
# when a movement ability is used, it charges with you in a duet attack.
# when asc: at the end of a charge, snowy flings his tail in an aoe
# freezing all enemies hit by his tail.

@export var dog_freedom_radius : float = 400
@export var charge_spd : float = 1
@export var charge_extra_dist = 100

# single attack
var target : BaseEnemy

# dog charge
var is_charging : bool = false
var charge_pos : Vector2 = Vector2.ZERO

func _init() -> void:
	action_name = "Dog"
	card_desc = "snowy!"
	action_icon_path = "res://assets/icons/dog_icon.png"

# Connect any signals from the hero here.
func _enter_tree() -> void:
	# all movement abilities are on ability2.
	hero.ability_2.ability_used.connect(on_movement_ability_used)
	
# Write logic below here....
func _ready() -> void:
	pass

# Update is called by the main character
func _update(_delta:float) -> void:
	super(_delta)
	
	
	
	# charge logic
	if !is_charging: return
	position = position.move_toward(charge_pos, charge_spd)
	if position == charge_pos:
		is_charging = false

# Dog Idle Behaviour, no enemies.
func idle_logic() -> void:
	# dog in alert
	# follow player but in an random offset.
	
	
	pass

# Dog attack behaviour, starts once you have a target.
func attack_logic() -> void:
	pass

func _upgrade() -> void:
	super()

func on_movement_ability_used() -> void:
	# Charges towards the end of the ability's position + a little extra distance.
	# both ability2s have new_position as their variable
	
	charge_pos = hero.ability_2.new_position + position.direction_to(hero.ability_2.new_position) * charge_extra_dist
	is_charging = true

# Override to apply stat changes
func set_item_stats() -> void:
	super()
