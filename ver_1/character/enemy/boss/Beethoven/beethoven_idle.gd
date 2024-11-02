class_name BeethovenIdle
extends BossAbility

var target : BaseHero
var old_pos : Vector2

@export_category("Decision Making")
## Range till boss starts auto-attacking close players
@export var melee_range : float = 1000 

@export var off_time_after_attack : float = 0.5
var current_off_time : float = 0
var on_cd_time : bool = false

var last_used_atk : BossAbility = null

@export_group("Sine Movement")
@export var amplitutde : float = 10
@export var speed : float = 100

var current_delta # this is used for physics update.
var rng = RandomNumberGenerator.new()


func enter() -> void:
	super()
	if last_used_atk: 
		on_cd_time = true
		current_off_time = 0
	
	target = GameManager.Instance.players.pick_random()
	old_pos = boss.global_position
	current_delta = 0

func update(delta) -> void:
	if on_cd_time:
		current_off_time += delta
		if current_off_time >= off_time_after_attack:
			on_cd_time = false
			current_off_time = 0
		#print("rest")
	else:
		#print("checking")
		check_if_player_in_range()

# Moves towards player in a sine wave movement, bobbles up and down if not.
func physics_update(delta) -> void:
	# move towards the player
	super(delta)
	if on_cd_time:
		current_delta += delta * speed * 5
		var new_pos = Vector2(boss.global_position.x, boss.global_position.y - (sin(deg_to_rad(current_delta)) * amplitutde))
		boss.velocity = (new_pos-old_pos)/delta
		old_pos = new_pos
		boss.move_and_slide()
		return
	else:
		current_delta += delta * speed
		
		var dir = (target.global_position - boss.global_position).normalized()
		
		# Flip direction vector perpendicular
		dir = Vector2(dir.y, dir.x)
		
		var new_pos = boss.global_position + (sin(deg_to_rad(current_delta)) * amplitutde) * dir
		new_pos += boss.char_stats.spd * delta * (target.global_position - boss.global_position).normalized()
		boss.velocity = (new_pos - old_pos)/delta 
		old_pos = new_pos 
		
		boss.move_and_slide()

func exit() -> void:
	current_delta = 0

# Chooses between Zoning Strike & Dash Combos
func decide_attack() -> void:
	var decision = rng.randi_range(0,2)
	if decision == 0 or decision == 1:
		state_change.emit(self, "BeethovenDash")
	else:
		state_change.emit(self, "ZoningStrike")

func check_if_player_in_range() -> void:
	if target.global_position.distance_to(global_position) <= melee_range:
		last_used_atk = (boss as Beethoven).dash
		decide_attack()
