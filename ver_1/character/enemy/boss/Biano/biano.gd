class_name Biano
extends BaseBoss

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox


func _enter_tree() -> void:
	super()
	char_id = 21

# process your states here
func _process(delta: float) -> void:
	super(delta)

#override this to add your states in 
func _init_states():
	pass

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
