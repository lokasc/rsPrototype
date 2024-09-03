class_name TurretItem
extends BaseItem

@onready var turret = load("res://ver_1/actions/items/turret.tscn")

@export_category("Deploying stats")
@export var deploy_range : int
@export var deploy_cd : float
@export var deploy_amount : int

@export_category("Turret stats")
@export var damage_per_tick : float# dmg per shot
@export var damage_tick_time : float # fire_rate
@export var turret_range : int
@export var turret_duration : float

var current_time : float
var turret_list: Array[Turret] = []

func _init() -> void:
	action_name = "Buildin a Sentry!"
	desc = "No spies be sappin' my sentry now"
	action_icon_path = "res://assets/icons/turret.png"

func _enter_tree() -> void:
	super()
	current_time = 0
	a_stats.atk = damage_per_tick
	a_stats.cd = deploy_cd

func _update(delta) -> void:
	_update_all_turrets(delta)
	current_time += delta
	if current_time >= a_stats.cd:
		for i in range(deploy_amount):
			if !multiplayer.is_server(): return
			spawn_turret.rpc(decide_spawn_location())
		current_time = 0

func _update_all_turrets(delta) -> void:
	for x : Turret in turret_list:
		x._update(delta)

func _upgrade() -> void:
	super()
	if level % 2 == 0:
		deploy_amount += 1
	deploy_range += 20
	damage_per_tick += 20
	turret_range += 5
	
	set_item_stats()

# Server decides location, passes to all clients.
func decide_spawn_location() -> Vector2:
	if !multiplayer.is_server(): return Vector2.ZERO
	return hero.global_position + Vector2(randi_range(-deploy_range,deploy_range),randi_range(-deploy_range,deploy_range))

# 1. Decide location
# 2. Spawn on all clients with location
# 3. Only sync the direction of the turret when a target changed. 
@rpc("authority", "call_local")
func spawn_turret(spawn_location : Vector2) -> void:
	var new_turret : Turret = turret.instantiate()
	new_turret.global_position = spawn_location
	new_turret.item = self
	set_turret_stats(new_turret)
	new_turret.destroy_turret.connect(on_destroy_turret)
	turret_list.append(new_turret)
	GameManager.Instance.net.spawnable_path.add_child(new_turret)
	
func on_destroy_turret(p_turret) -> void:
	turret_list.erase(p_turret)
	p_turret.queue_free()

func set_turret_stats(new_turret : Turret) -> void:
	new_turret.damage_per_tick = damage_per_tick
	new_turret.initial_tick_time = damage_tick_time
	new_turret.damage_per_tick = damage_per_tick
	new_turret.turret_duration = turret_duration
	new_turret.turret_range = turret_range

func set_item_stats() -> void:
	a_stats.atk = damage_per_tick
	a_stats.cd = deploy_cd
