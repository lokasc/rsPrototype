class_name OneShot
extends BaseEnemy

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

@export var update_frequency : float = 3
var current_update_time : float = 0

func _init() -> void:
	super()
	
func _enter_tree() -> void:
	super()
	# assign random time, so enemies dont update all together
	if multiplayer.is_server():
		current_update_time = randf_range(1, update_frequency)
	pass

func _ready() -> void:
	super()
	hitbox.area_entered.connect(on_hit)
	sprite = $AnimatedSprite2D
	sprite.play("default")
	x_scale = sprite.scale.x

func _process(delta: float) -> void:
	current_update_time += delta
	
	if current_update_time >= update_frequency:
		target = get_closest_target_position()
		current_update_time = 0
	pass

func _physics_process(_delta:float) -> void:
	if can_move == true:
		move_to_target(target)
	if frozen:
		collidebox.disabled = true
	else:
		collidebox.disabled = false

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var hero = area.get_parent() as BaseHero
	if hero == null: return
	
	# TODO: not networked yet
	# need to calculate how much damage based on 
	# the attack value of this ability + my character's attack value
	hero.take_damage(char_stats.atk)
