class_name Beethoven
extends BaseBoss

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

@export var sting : BossAbility 


func _enter_tree() -> void:
	super()
	char_id = 22

# process your states here
func _process(delta: float) -> void:
	super(delta)

func _physics_process(delta : float) -> void:
	super(delta)

#override this to add your states in 
func _init_states():
	_parse_abilities(sting)
	super()
	pass

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
