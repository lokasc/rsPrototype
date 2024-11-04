class_name RPLProjectile1
extends BaseProjectile

var is_ascended : bool = false
var asc_1_dmg_multiplier : int 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_ascended:
		damage *= asc_1_dmg_multiplier

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_hitbox_area_entered(area: Area2D) -> void:
	var character : BaseCharacter = null
	if area.get_parent() is BaseEnemy:
			character = area.get_parent()
			if !character: return
			visible = false
			character.take_damage(damage)
			if multiplayer.is_server() and !is_ascended:
				call_deferred("queue_free")
