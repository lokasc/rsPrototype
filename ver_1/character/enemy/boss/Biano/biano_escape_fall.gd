class_name BianoEscapeFall
extends BossAbility

### Biano jumps and lands to another area. 
# Biano leaves the spot, invulnerable and then slams the ground after picking another location
# Visuals: Biano flys up quickly, turns off their visuals, leaving a black circle to indicate his shadow.
# Then comes down slamming.

@export var inner_circle_radius : float = 200
@export var outer_circle_radius : float = 250

@export_group("Visuals")
@export var hitbox_end_scale : int # how big the hitbox and sprite in the end.
@export var scale_at_start : int = 2 # how large is our container (contains the hitbox and sprite)
@export var modulation_at_start : Color = Color(0, 0, 0, 0.576)
@export_subgroup("Timing")
@export var fly_time : float # how long biano will fly up
@export var sky_move_time : float # how long will biano move to new position
@export var time_to_fall : float # how long it takes for biano to crash onto the ground (We can calibrate this)

@onready var circle_hitbox = $Container/HitBox
@onready var shadow_sprite = $Container/HitBox/ShadowSprite
@onready var container = $Container


# bools to track our state
var is_flying : bool # going up.
var is_moving : bool # moving towards the new spot
var is_falling : bool # fall down onto the player.

var original_y_pos : float
var new_position # position our boss will move towards.
var rng = RandomNumberGenerator.new()
var sky_move_speed 
var fly_speed
var fall_speed

func _ready() -> void:
	super()
	shadow_sprite.visible = false

func enter() -> void:
	super()
	boss.invulnerable = true
	is_flying = true
	new_position = decide_new_location()
	original_y_pos = boss.global_position.y
	
	# calculate speed from time and dist:
	fly_speed = 2000/fly_time
	sky_move_speed = abs(new_position.distance_to(boss.global_position))/sky_move_time
	fall_speed = 2000/time_to_fall
	shadow_sprite.self_modulate = modulation_at_start
	container.scale = Vector2(scale_at_start, scale_at_start)

	# ^^ is calculating the distance between boss sprite position and 2000 meters up. 

func exit() -> void:
	super() # starts cd here.
	boss.sprite.visible = true
	shadow_sprite.visible = false

func update(_delta: float) -> void:
	super(_delta)
	
	#state_change.emit(self, "BianoIdle")

func physics_update(_delta: float) -> void:
	super(_delta)
	if is_flying:
		print("in flying")
		
		boss.sprite.position.y = move_toward(boss.sprite.position.y, boss.sprite.position.y-2000, fly_speed * _delta)
		
		if boss.sprite.position.y <= original_y_pos - 2000:
			boss.sprite.visible = false
			is_flying = false
			is_moving = true
			shadow_sprite.visible = true
	
	if is_moving:
		print("in moving")
		boss.global_position = boss.global_position.move_toward(new_position, _delta*sky_move_speed)
		
		
		if boss.global_position == new_position:

			is_moving = false
			boss.sprite.visible = true
			is_falling = true
	
	if is_falling:
		
		print("in falling")
		boss.sprite.position.y = move_toward(boss.sprite.position.y, 0, fall_speed * _delta)
		# Modify scale and color over time
		
		container.scale += Vector2(_delta * (hitbox_end_scale-scale_at_start), _delta * (hitbox_end_scale-scale_at_start))
		shadow_sprite.self_modulate.r += _delta # no multiplier because its from 0 -> 1
		shadow_sprite.self_modulate.g += _delta
		shadow_sprite.self_modulate.b += _delta
		shadow_sprite.self_modulate.a += (1 -modulation_at_start.a) * _delta
		
		if boss.sprite.position.y >= 0:
			shadow_sprite.self_modulate = Color(1,1,1,1)
			container.scale = Vector2(hitbox_end_scale, hitbox_end_scale)
			on_slam()

# Takes the furtherest position from the players
func decide_new_location() -> Vector2:
	# Spawning at a random circle edge:
	
	var angle = rng.randf_range(0, TAU)
	var rand_radius = rng.randf_range(inner_circle_radius, outer_circle_radius)
	return rand_radius * Vector2.from_angle(angle)

func on_slam():
	if !multiplayer.is_server(): return
	
	for area : Area2D in circle_hitbox.get_overlapping_areas():
		_on_hit_box_area_entered(area)
	
	
	is_falling = false
	is_flying = false
	is_moving = false
	state_change.emit(self, "BianoIdle")

func _on_hit_box_area_entered(area: Area2D) -> void:
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
	
	if !character: return
	
	if !multiplayer.is_server(): return
	
	character.add_status("Knockback", [250, boss.global_position, 15])
