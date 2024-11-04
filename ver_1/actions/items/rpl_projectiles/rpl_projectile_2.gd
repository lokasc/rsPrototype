class_name RPLProjectile2
extends BaseProjectile

var spawn_range : int
var duration : float = 1
var is_ascended : bool = false

@onready var timer : Timer = $DurationTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start(duration)
	position = position + Vector2(randi_range(-spawn_range,spawn_range),randi_range(-spawn_range,spawn_range))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_hitbox_area_entered(area: Area2D) -> void:
	# typecasting
	var character : BaseCharacter = null
	if area.get_parent() is BaseEnemy:
		character = area.get_parent()
		if !character: return
		if multiplayer.is_server():
			character.take_damage(damage)

func _on_duration_timer_timeout() -> void:
	if multiplayer.is_server():
		visible = false
		call_deferred("queue_free")
