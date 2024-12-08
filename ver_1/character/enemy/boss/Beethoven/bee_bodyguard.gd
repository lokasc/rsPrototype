class_name BeeBodyguard
extends BossAbility

### Bee dives towards Biano, dealing damage in an area while body blocking all damage for Biano.
@export_category("Mechanics")
@export var bodyguard_duration : float # how long will bee protect biano
@export var dive_dmg : float
@export var dive_speed : float # the speed bee will reach to biano.

@export_group("dive heuristics")
@export var dive_min_offset : float # min distance between bee and biano
@export var dive_cutoff : float # max range to consider players when diving. 

var is_moving : bool = false # if bee is moving towards biano
var is_bodyguard : bool = false # if bee is protected biano
var dive_to_position # this is the position between the players and boss.
var dive_hitbox_linger_time = 0.1 # lingering hitbox (how long the hitbox lasts..)

@onready var area_bodyguard = $AreaBodyguard
@onready var area_bg_sprite = $AreaBodyguard/ShieldSprite

# move areabodyguard to parent.
func _ready() -> void:
	super()
	# the boss var is initialized yet, gotta use a different method.
	area_bodyguard.call_deferred("reparent", get_parent(), true)
	area_bodyguard.set_deferred("monitorable", false)

func enter() -> void:
	super()
	
	dive_to_position = calculate_dive_position()
	is_moving = true
	$AreaDive.monitoring = false
	area_bodyguard.monitoring = false

func exit() -> void:
	super() # starts cd here.
	
	# safely disable everything
	$LingerTimer.stop()
	$BGTimer.stop()
	$AreaDive.monitoring = false
	area_bodyguard.monitoring = false
	area_bodyguard.monitorable = false #players can hit this and do x2 damage
	$AreaDive/AnimatedSprite2D.visible = false
	$AreaDive/AnimatedSprite2D.stop()
	boss.ally.invulnerable = false
	area_bg_sprite.visible = false

func update(_delta: float) -> void:
	super(_delta)
	pass

func physics_update(_delta: float) -> void:
	super(_delta)
	if is_moving:
		boss.velocity = global_position.direction_to(dive_to_position) * dive_speed
		boss.move_and_slide()
		
		# check if we under or over shoot
		if abs(global_position.distance_to(dive_to_position)) <= 15:
			is_moving = false
			$LingerTimer.stop()
			$LingerTimer.start(dive_hitbox_linger_time)
			$AreaDive.monitoring = true
			
			# Show visuals and check if playing already.
			$AreaDive/AnimatedSprite2D.stop()
			$AreaDive/AnimatedSprite2D.visible = true
			$AreaDive/AnimatedSprite2D.play()

# returns the mid of point of all points within a radius (+ extra edge cases)
func calculate_dive_position() -> Vector2:
	var positions_to_consider = []
	var mid_point : Vector2 = Vector2.ZERO
	var final_point : Vector2 = Vector2.ZERO
	positions_to_consider.append(boss.ally.global_position)
	
	# get all positions that are within a radius.
	for player in GameManager.Instance.players:
		if abs(player.global_position.distance_to(boss.ally.global_position)) >= dive_cutoff:
			continue
		positions_to_consider.append(player.global_position)
	
	# get the sum of positions.
	for pos in positions_to_consider:
		mid_point.x += pos.x
		mid_point.y += pos.y
	
	mid_point.x /= positions_to_consider.size()
	mid_point.y /= positions_to_consider.size()
	final_point = mid_point
	
	if mid_point.distance_to(boss.ally.global_position) <= dive_min_offset:
		var direction = mid_point.direction_to(boss.ally.global_position)
		final_point = -direction * dive_min_offset + boss.ally.global_position
	
	return final_point

func _on_area_dive_area_entered(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
		
	if !character: return 	# do not execute on non-characters or nulls
	character.take_damage(boss.char_stats.atk/boss.initial_atk * dive_dmg)

# when hitbox ends, start protecting for ally
func _on_linger_timer_timeout() -> void:
	$AreaDive.monitoring = false
	$BGTimer.stop()
	$BGTimer.start(bodyguard_duration)
	
	# Start protecting 
	boss.ally.invulnerable = true
	area_bodyguard.monitoring = true
	area_bodyguard.monitorable = true
	area_bg_sprite.visible = true
	
	# move hitbox to the middle of two bosses
	area_bodyguard.global_position = (boss.global_position + boss.ally.global_position)/2

func _on_bg_timer_timeout() -> void:
	state_change.emit(self, "BeethovenIdle")
