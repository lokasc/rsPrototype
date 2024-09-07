extends Node2D

@export var dmg : float # connct to boss...
@export var spd : float # connct to boss...

var initial_boss_atk : float
var boss_atk : float
# we will try to reuse this piece of code for both pRojectiles.

func _enter_tree() -> void:
	pass

func _ready() -> void:
	$ProjectileSprite.frame = randi_range(0,2)

func _physics_process(delta: float) -> void:
	global_position += transform.y * delta * spd

func _on_hit_box_area_entered(area: Area2D) -> void:
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
	
	if !character: return
	
	if !multiplayer.is_server(): return
	
	character.take_damage(boss_atk/initial_boss_atk * dmg)
