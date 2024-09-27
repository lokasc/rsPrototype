class_name ProjectileEnemy
extends BaseEnemy

@onready var collidebox : CollisionShape2D = $CollisionBox

## Min range where the enemy will start shooting.
@export var min_range : float

## Max range where the enemy will start shooting, moves towards the player if they are outside this range
@export var max_range : float

@export var look_ahead : float

@export_group("Projectile")
@export var projectile_speed : int
@export var projectile_dmg : float
@export var projectile_size : float
@export var shooting_period : float 
@export var projectile_scene : PackedScene

@onready var spawn_path = get_parent()
@onready var hitbox : Area2D = $HitBox

var actual_distance_to_shoot
var current_time = 0

func _init() -> void:
	super()
	
func _enter_tree() -> void:
	super()
	pass

func _ready() -> void:
	super()
	sprite = $AnimatedSprite2D
	sprite.play("default")
	x_scale = sprite.scale.x
	
	# decide on a range:
	actual_distance_to_shoot = randf_range(min_range, max_range)

# do not get a new enemy per second 
func _process(delta: float) -> void:
	pass


func _physics_process(_delta:float) -> void:
	if can_move == true:
		var distance_to_target = global_position.distance_to(target.global_position)
		if distance_to_target > max_range:
			#print("Moving towards: " + str(distance_to_target))
			move_to_target(target)
		#elif distance_to_target <= min_range:
			#print("Moving away: " + str(distance_to_target))
			#move_away_from_target(target)
		else:
			current_time += _delta
			if current_time >= shooting_period:
				shoot_projectile()
				current_time = 0
	
	collidebox.disabled = frozen

func move_to_target(p_target = null) -> void:
	if p_target == null: return
	# direction need to go towards
	var direction : Vector2 = global_position.direction_to(p_target.global_position)
	var distance : float = global_position.distance_to(p_target.global_position)
	
	if distance < actual_distance_to_shoot:
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

func move_away_from_target(p_target = null) -> void:
	if p_target == null: return

# direction need to go towards
	var direction : Vector2 = global_position.direction_to(p_target.global_position)
	var distance : float = global_position.distance_to(p_target.global_position)
	
	if distance > actual_distance_to_shoot:
		velocity = Vector2.ZERO
	else:
		velocity = -direction * char_stats.spd
	
	if direction.x < 0:
		sprite.scale.x = x_scale
	elif direction.x > 0:
		sprite.scale.x = x_scale * -1
	else:
		sprite.scale.x = x_scale * -1
	move_and_slide()

#@rpc("authority", "call_local")
func shoot_projectile() -> void:
	if !multiplayer.is_server(): return
	target = get_closest_target_position()
	if target == null: return
	
	var new_proj : BaseProjectile = projectile_scene.instantiate()
	new_proj.global_position = global_position
	new_proj.look_at(target.global_position + target.velocity.normalized() * look_ahead)
	new_proj.set_projectile_stats(projectile_dmg, projectile_speed, projectile_size)
	
	#rmb to spawn it here
	GameManager.Instance.net.spawnable_path.add_child(new_proj, true)

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var hero = area.get_parent() as BaseHero
	if hero == null: return
	
	hero.take_damage(char_stats.atk)
