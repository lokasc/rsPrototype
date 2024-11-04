class_name ShooterProjectile
extends BaseProjectile


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_hitbox_area_entered(area: Area2D) -> void:
	# typecasting
	var character : BaseCharacter = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
		if !character: return
		if multiplayer.is_server():
			visible = false
			character.take_damage(damage)
			call_deferred("queue_free")
