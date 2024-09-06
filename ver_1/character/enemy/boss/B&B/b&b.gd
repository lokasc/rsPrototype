class_name BeethovenAndBiano
extends BaseBoss

# Attack pattern
# 1. Ability1: SLAM
# 2. Ability2: Ring
# 3. if current_health <= max_health/3 * 2
# 4. Ability1: SLAM
# 5. Ability3: RAINFALL
# 6. if current_health <= max_health/3
# 7. Ability1: SLAM
# 8. Ability4: RAINFALL + Ring.
# 9. Die, go back to china.

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

@export_category("Attacks")
@export var slam : BossAbility
@export var rain : BossAbility
@export var ring : BossAbility

var phase : int = 1

func _init() -> void:
	super()
	max_health = 1000
	
func _enter_tree() -> void:
	super()

func _ready() -> void:
	super()

func _process(delta: float) -> void:
	super(delta)
	print(current_state)
	
	if phase == 3 && current_health >= 0:
		phase_three_logic(delta)
		return
	
	# Check for phase 2 first incase player skips a phase.
	if current_health <= max_health/3 &&( phase == 1 || phase == 2 ):
		phase = 3
		printerr("Going to phase 3!")
		current_state.exit()
		current_state = null
		rain.enter()
		ring.enter()

	elif current_health <= 2*(max_health/3) && phase == 1:
		phase = 2
		printerr("Going to phase 2!")
		state_change_from_any("BnBSlam")

func phase_three_logic(delta):
	rain.update(delta)
	ring.update(delta)


func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return

# Override this here to change the stats of the character.
func _init_stats():
	super()

func _init_states():
	_parse_abilities(slam)
	_parse_abilities(rain)
	_parse_abilities(ring)
	super()
