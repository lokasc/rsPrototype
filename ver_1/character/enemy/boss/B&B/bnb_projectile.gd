extends Node2D

@export var is_rain : bool = false
@export var dmg : float # connct to boss...
@export var spd : float # connct to boss...
@export var height : float # Distance it needs to travel before disappearing.

@export var circle_container : Node2D

@onready var expanding_circle : Sprite2D = $CircleContainer/ExpandingCircle
@onready var projectile_container = $ProjectileContainer
@onready var circle_hitbox : Area2D = $CircleContainer/HitBox

var dist_travelled : float = 0
var initial_boss_atk : float
var boss_atk : float
# we will try to reuse this piece of code for both pRojectiles.

func _enter_tree() -> void:
	pass

func _ready() -> void:
	# Change active hitboxes
	circle_hitbox.monitoring = is_rain
	projectile_container.get_child(1).monitoring = !is_rain
	
	if is_rain:
		projectile_container.get_child(0).frame = 3
		circle_hitbox.monitoring = true
		circle_container.visible = true
		circle_container.global_position.y += height
		dist_travelled = 0
		expanding_circle.scale = Vector2.ZERO
	else:
		projectile_container.get_child(0).frame = randi_range(0,2)
		circle_container.visible = false

func _process(delta: float) -> void:
	if is_rain:
		# animate the scale to match current.
		# remap distance:
		 
		var current_scale : float = min(1, dist_travelled/height)
		expanding_circle.scale = Vector2(current_scale, current_scale)

func _physics_process(delta: float) -> void:
	if is_rain:
		projectile_container.global_position.y += delta * spd
		dist_travelled += delta * spd
		if dist_travelled >= height:
			on_projectile_land()
	else:
		global_position += transform.y * delta * spd
		dist_travelled += delta * spd
		if dist_travelled >= 1000:
			queue_free()

func on_projectile_land():
	if !multiplayer.is_server(): return
	
	for area : Area2D in circle_hitbox.get_overlapping_areas():
		_on_hit_box_area_entered(area)
	queue_free()

func _on_hit_box_area_entered(area: Area2D) -> void:
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
	
	if !character: return
	
	if !multiplayer.is_server(): return
	
	character.take_damage(boss_atk/initial_boss_atk * dmg)
	visible = false
	call_deferred("queue_free")
