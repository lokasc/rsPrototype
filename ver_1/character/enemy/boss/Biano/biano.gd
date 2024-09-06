class_name Biano
extends BaseEnemy

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

@export var update_frequency : float = 3
var current_update_time : float = 0

func _init() -> void:
	super()
	max_health = 1000
	
func _enter_tree() -> void:
	super()
	# assign random time, so enemies dont update all together
	if multiplayer.is_server():
		current_update_time = randf_range(1, update_frequency)
	pass

func _ready() -> void:
	super()


func _process(delta: float) -> void:
	pass

func _physics_process(_delta:float) -> void:
	pass

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
