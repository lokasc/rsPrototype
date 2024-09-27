class_name BeethovenDash
extends BossAbility

### Dashes towards the player, appearing behind them.
@export_category("Mechanics")
@export var offset : float
@export var dash_count : float = 2

@export_group("Curve")
@export var desired_time : float = 3
@export var y_curve : Curve

var current_dash_count = 0

var is_direction_changed : bool

var time = 0
var target : BaseHero

var direction
var distance
var old_position
var curve_position

# Beethoven dashes forward piercing you and slashes towards you
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func enter() -> void:
	super()
	target = choose_player()
	distance = (target.global_position - global_position).length()
	is_direction_changed = false
	#target.global_position + target.velocity.normalized() * desired_time
	
	direction = (target.global_position - global_position).normalized()
	distance += offset

func exit() -> void:
	super()
	time = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	var old_position : Vector2
	var old_y
	var delta_curve_position
	
	if !is_direction_changed:
		boss.show_warning.emit(target.global_position ,0)
	
	if time < desired_time:
		old_y = y_curve.sample(time/desired_time)
		
		# Limit Time 
		time = min(time + delta, desired_time)
		
		if !is_direction_changed && time >= 0.5:
			is_direction_changed = true
			var future_pos = target.global_position + target.velocity.normalized() * 100
			direction = (future_pos - global_position).normalized()
			boss.hide_warning.emit()
			
		# Calculate delta X position
		delta_curve_position = y_curve.sample(time/desired_time) - old_y
	
		boss.velocity = ((delta_curve_position  * distance) / delta) * direction
		boss.move_and_slide()
	else:
		boss.velocity = Vector2.ZERO
		
		if current_dash_count < dash_count - 1:
			current_dash_count += 1
			state_change.emit(self, "BeethovenDash")
		else:
			current_dash_count = 0
			state_change.emit(self, "BeethovenIdle")
