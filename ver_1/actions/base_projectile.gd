class_name BaseProjectile
extends Node2D

@export var damage : float
@export var speed : float

var dist_travelled : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	global_position += transform.x * delta * speed
	dist_travelled += delta * speed
	if dist_travelled >= 1000:
		if multiplayer.is_server():
			queue_free()


# called by abilites
func set_projectile_stats(_damage : float, _speed : int, _size : float) -> void:
	damage = _damage
	speed = _speed
	scale = _size * Vector2.ONE

func _on_hitbox_area_entered(area: Area2D) -> void:
	pass
	
