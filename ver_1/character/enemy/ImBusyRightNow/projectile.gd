class_name BaseProjectile
extends Node2D

@export var damage : float
@export var speed : float

var dist_travelled = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Spawnned")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	global_position += transform.y * delta * speed
	dist_travelled += delta * speed
	if dist_travelled >= 1000:
		queue_free()
	pass

# called by abilites
func set_projectile_stats(_sprites : SpriteFrames) -> void:
	$AnimatedSprite2D.sprite_frames = _sprites
	pass
