class_name BaseProjectile
extends Node2D

@export var damage : float
@export var speed : float

var dist_travelled = 0

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
		queue_free()
	pass

# called by abilites
func set_projectile_stats(_sprites : SpriteFrames) -> void:
	$AnimatedSprite2D.sprite_frames = _sprites
	pass


func _on_hitbox_area_entered(area: Area2D) -> void:
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
	
	if !character: return
	
	visible = false
	
	if multiplayer.is_server():
		character.take_damage(damage)
		call_deferred("queue_free")
	
