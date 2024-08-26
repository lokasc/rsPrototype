class_name MinorBug
extends BaseEnemy

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

func _init() -> void:
	super()
	pass

func _enter_tree() -> void:
	super()
	pass

func _ready() -> void:
	super()
	hitbox.area_entered.connect(on_hit)
	sprite = $AnimatedSprite2D
	sprite.play("default")
	x_scale = sprite.scale.x #Sets initial x scale dimension

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

func take_damage(dmg) -> void:
	super(dmg)

# TODO: FSM or STATE MACHINE for enemy
func _decide(target = null) -> void:
	if target == null:
		return
