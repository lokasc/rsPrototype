class_name BeethovenPumpFake
extends BossAbility

@export var y_curve : Curve
@export var desired_time := 3
var time = 0
var target : BaseHero

var direction
var distance
var old_position
var curve_position

# Beethoven dashes forward piercing you and slashes towards you
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func enter() -> void:
	super()
	print("Entered!")
	target = choose_player()
	distance = (target.global_position - global_position).length()
	direction = (target.global_position - global_position).normalized()
	distance += 100
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
	if time < desired_time:
		#Time/desiredTime is the percentage of the "progess on the curve"
		old_y = y_curve.sample(time/desired_time)
		
		# Limit Time 
		time = min(time + delta, desired_time)
		#Get needed velocity each  physics_frame by subtracting current point with previous point on curve then multiplying with distance and direction
		#Divides result with delta_time since move_and_slides automatically multiplies delta and we don't want that in this case
		
		
		# Calculate delta X position
		delta_curve_position = y_curve.sample(time/desired_time) - old_y
		#delta_curve_position = Vector2(0, y_curve.sample(time/desired_time) - old_y)
		
		
		# delta_curve_position is within range of 0-1, multiply it by
		# our distance for the full distance of movement.
		# divide by delta_time cuz we already calculate per delta
		# and move_and_slide divide delta already in its functions.
		boss.velocity = ((delta_curve_position  * distance) / delta) * direction
		
		boss.move_and_slide()
	else:
		boss.velocity = Vector2.ZERO
		state_change.emit(self, "BeethovenIdle")
