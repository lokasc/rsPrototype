class_name BianoIdle
extends BossAbility

var target : BaseHero
var old_pos : Vector2

@export_category("Decision Making")
## Min Range player needs to be in for biano to target them
@export var detection_range : float = 1000 

## Distance at which Biano is likely to jump away
@export var fear_distance : float = 100

@export var off_time_after_attack : float = 0.5
var current_off_time : float = 0
var on_cd_time : bool = false

var last_used_atk : BossAbility = null # this is to keep track but also ensure we dont cooldown the moment we enter.

func enter() -> void:
	super()
	if last_used_atk: 
		on_cd_time = true
		current_off_time = 0

func update(delta) -> void:
	if on_cd_time:
		current_off_time += delta
		if current_off_time >= off_time_after_attack:
			on_cd_time = false
			current_off_time = 0
	else:
		target = GameManager.Instance.players.pick_random()
		check_if_player_in_range()

# Moves towards player in a sine wave movement, bobbles up and down if not.
func physics_update(delta) -> void:
	# move towards the player
	super(delta)

func exit() -> void:
	pass

# Chooses between Zoning Strike & Dash Combos
func decide_attack() -> void:
	# check for both players, if too close we jump away
	#for x in GameManager.Instance.players:
		#if global_position.distance_to(x.global_position) <= fear_distance:
			#state_change.emit(self, "BianoEscapeFall")
			#return
	
	
	last_used_atk = boss.idle
	
	#state_change.emit(self, "BnBRain")
	#state_change.emit(self, "BianoCoveringFire")
	state_change.emit(self, "BianoEscapeFall")

# if the player is not in range, we check after a interval 
func check_if_player_in_range() -> void:
	if target.global_position.distance_to(global_position) <= detection_range:
		decide_attack()
