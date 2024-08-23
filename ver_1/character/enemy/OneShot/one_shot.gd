class_name OneShot
extends BaseEnemy

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

var x_scale : int

func _init():
	super()
	pass

func _enter_tree():
	super()
	pass

func _ready() -> void:
	super()
	hitbox.area_entered.connect(on_hit)
	sprite.play("default")
	x_scale = sprite.scale.x #Sets initial x scale dimension

func _physics_process(_delta):
	if can_move == true:
		move_to_target(target)
	if frozen:
		collidebox.disabled = true
	else:
		collidebox.disabled = false

func on_hit(area : Area2D):
	if !multiplayer.is_server(): return
	
	# typecasting
	var hero = area.get_parent() as BaseHero
	if hero == null: return
	
	# TODO: not networked yet
	# need to calculate how much damage based on 
	# the attack value of this ability + my character's attack value
	hero.take_damage(char_stats.atk)

func take_damage(dmg):
	super(dmg)

# TODO: FSM or STATE MACHINE for enemy
func _decide(target = null):
	if target == null:
		return

func move_to_target(target = null):
# direction the pest needs to go towards:
	var direction = global_position.direction_to(target.global_position)
	var distance = global_position.distance_to(target.global_position)
	
	if distance < 15:
		velocity = Vector2.ZERO
	else:
		velocity = direction * char_stats.spd
	
	if direction.x < 0:
		sprite.scale.x = x_scale
	elif direction.x > 0:
		sprite.scale.x = x_scale * -1
	else:
		sprite.scale.x = x_scale * -1
	move_and_slide()
