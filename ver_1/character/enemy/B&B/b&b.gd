class_name BeethovenAndBiano
extends BaseEnemy

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

func _init() -> void:
	super()
	max_health = 1000
	
func _enter_tree() -> void:
	super()

func _ready() -> void:
	super()


func _process(delta: float) -> void:
	pass

func _physics_process(_delta:float) -> void:
	pass

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
