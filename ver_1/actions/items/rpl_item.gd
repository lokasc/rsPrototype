class_name RPLItem
extends BaseItem

@export_category("Shooting stats")
## How often the item shoots
@export var shooting_period : float
## How long it takes the dice to roll and decide
@export var picking_duration : float
## An array that determines the chance of getting each projectile, determined by picking randomly from the array. Projectile ID ranges from 1 - 4 inclusive.
@export var projectile_id_array : Array[int]

@export_category("Projectile stats") # Projectile 3 reuses the projectile used for Projectile 1
@export var projectile_1_scene : PackedScene = preload("res://ver_1/actions/items/rpl_projectiles/rpl_projectile_1.tscn")
@export var projectile_2_scene : PackedScene = preload("res://ver_1/actions/items/rpl_projectiles/rpl_projectile_2.tscn")
@export var projectile_3_scene : PackedScene = preload("res://ver_1/actions/items/rpl_projectiles/rpl_projectile_1.tscn")

@export_subgroup("Projectile 1")
@export var projectile_1_speed : int
@export var projectile_1_dmg : float = 1
@export var projectile_1_size : float = 1

@export_subgroup("Projectile 2")
@export var projectile_2_dmg : float
## How long the projectiles last
@export var projectile_2_duration : float = 0.5
@export var projectile_2_size : float = 1
@export var projectile_2_amount : int
@export var projectile_2_range : float

@export_subgroup("Projectile 3")
@export var projectile_3_speed : int
@export var projectile_3_dmg : float
@export var projectile_3_size : float = 1
@export var projectile_3_amount : int
## Projectiles will be shot at a target +- the spread
@export var projectile_3_spread : int

@export_category("Ascended")
@export_subgroup("Projectile 1")
@export var asc_1_dmg_multiplier : int = 1000
@export_subgroup("Projectile 2")
@export var asc_2_aoe_multiplier : float = 1
@export var asc_2_dur_multiplier : float = 1
@export var asc_2_dmg_multiplier : float = 1
@export_subgroup("Projectile 3")
@export var asc_3_dmg_multiplier : float = 1

var current_time : float # the time which determines how often the projectile is shot
var display_current_time : float # the time which determines how often the projectile is shot
var display_period : float = 0.08 # determines how quickly the roll number changes
var display_duration : float = 0.5 # determines how long the last number is displayed
var projectile_id : int # determines the projectile that will be shot

@onready var label : Label = $Label
@onready var label_timer : Timer = $LabelTimer

func _init() -> void:
	action_name = "R.P.L."
	card_desc = "Random Projectile Launcher. Shoots random projectiles depending on the number landed.\n[Projectile]"
	action_icon_path = "res://assets/icons/rpl_icon.png"

func _enter_tree() -> void:
	super()
	current_time = 0

func _ready() -> void:
	label.hide()
	set_item_stats()

func _update(delta) -> void:
	current_time += delta
	position = hero.global_position
	# Determines when to start displaying the rolls, displaying and picking are different
	if current_time >= shooting_period - picking_duration:
		label.show()
		display_current_time += delta
		projectile_id = randi_range(1,4)
		# Displays the number on a period
		if display_current_time >= display_period: # Makes it so that label text change is somewhat legible
			label.text = str(projectile_id)
			display_current_time = 0
		# Picks the number on a period
		if current_time >= shooting_period:
			current_time = 0
			projectile_id = projectile_id_array.pick_random()
			# Checking for edge cases
			if projectile_id > 4: projectile_id = 4
			if projectile_id < 1: projectile_id = 1
			
			label.text = str(projectile_id)
			label_timer.start(display_duration) # Displays the picked number for a duration
			
			# Shooting logic, if id is 4, it shoots all 3 variants
			if projectile_id == 4:
				for i in range(1,4):
					shoot_projectile(i)
			else:
				shoot_projectile(projectile_id)


func _upgrade() -> void:
	super()
	projectile_2_amount += 5
	projectile_2_dmg += 10
	projectile_2_range += 50
	projectile_3_amount += 5
	projectile_3_dmg += 15
	if is_ascended:
		projectile_2_dmg *= asc_2_dmg_multiplier
		projectile_2_size *= asc_2_aoe_multiplier
		projectile_2_duration *= asc_2_dur_multiplier
		projectile_3_dmg *= asc_3_dmg_multiplier
	set_item_stats()
	

func set_item_stats() -> void:
	a_stats.atk = 1 * hero.char_stats.atk/hero.initial_damage
	a_stats.aoe = hero.char_stats.aoe
	a_stats.dur = hero.char_stats.dur
	desc = "?????"

#NOTE: Projectile 3 reuses the projectile used for Projectile 1
func shoot_projectile(_id) -> void: 
	if !multiplayer.is_server(): return
	# Projectiles shoots in a random direction by aiming at target
	var target : Vector2 = global_position + Vector2(randf_range(-1,1),randf_range(-1,1)).normalized()
	if target == null: return
	match _id:
		1:
			if projectile_1_scene == null: return
			var new_proj_1 : BaseProjectile = projectile_1_scene.instantiate()
			
			# Setting the new projectile's position, direction and stats
			new_proj_1.global_position = global_position
			new_proj_1.look_at(target)
			new_proj_1.set_projectile_stats(projectile_1_dmg, projectile_1_speed, projectile_1_size)
			if is_ascended: 
				new_proj_1.is_ascended = true
				new_proj_1.asc_1_dmg_multiplier = asc_1_dmg_multiplier
			
			GameManager.Instance.net.spawnable_path.add_child(new_proj_1, true)
		2:
			if projectile_2_scene == null: return
			for count in range(projectile_2_amount): # Projectile 2 randomly assigns position on ready
				var new_proj_2 : BaseProjectile = projectile_2_scene.instantiate()
				
				# Setting the new projectile's position, direction and stats
				new_proj_2.global_position = global_position
				new_proj_2.spawn_range = projectile_2_range
				new_proj_2.duration = projectile_2_duration * a_stats.dur
				new_proj_2.set_projectile_stats(projectile_2_dmg * a_stats.atk, 0, projectile_2_size * a_stats.aoe)
				if is_ascended: new_proj_2.is_ascended = true
				
				GameManager.Instance.net.spawnable_path.add_child(new_proj_2, true)
		3:
			if projectile_3_scene == null: return
			for count in range(projectile_3_amount):
				var new_proj_3 : BaseProjectile = projectile_3_scene.instantiate()
				
				# Setting the new projectile's position, direction and stats
				new_proj_3.global_position = global_position
				### Current way of random spread, Would like to change this in the future so it goes clockwise evenly
				new_proj_3.look_at(target + Vector2(randi_range(-projectile_3_spread,projectile_3_spread),randi_range(-projectile_3_spread,projectile_3_spread)))
				new_proj_3.set_projectile_stats(projectile_3_dmg * a_stats.atk, projectile_3_speed, projectile_3_size * a_stats.aoe)
				if is_ascended: 
					new_proj_3.is_ascended = true
					new_proj_3.asc_1_dmg_multiplier = 1
				
				GameManager.Instance.net.spawnable_path.add_child(new_proj_3, true)

# More computational if there are more enemies, switched to use mouse position
func get_closest_target_position() -> Vector2:
	var closest_enemy : BaseEnemy = null 
	var closest_magnitude : float = 9999999
	for x : BaseEnemy in GameManager.Instance.spawner.spawn_path.get_children():
		if x.IS_DEAD: continue
		if x.global_position.distance_to(self.global_position) < closest_magnitude:
			closest_enemy = x
			closest_magnitude = x.global_position.distance_to(self.global_position)
	return closest_enemy.global_position


func _on_label_timer_timeout() -> void:
	label.hide()
