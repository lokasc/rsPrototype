class_name NonInteractiveProjectile
extends BaseProjectile


func _physics_process(delta: float) -> void:
	global_position -= transform.y * delta * speed
	dist_travelled += delta * speed
	if dist_travelled >= 500:
		queue_free()
	pass


# when interacted do nothing.
func _on_hitbox_area_entered(area: Area2D) -> void:
	return
