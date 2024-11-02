class_name BeethovenDash
extends BossAbility

### Dashes towards the player, appearing behind them.
@export_category("Mechanics")
@export var initial_dmg : float = 25
@export var offset : float
@export var dash_count : float = 2

@export_group("Curve")
@export var desired_time : float = 3 # How long a dash lasts 
@export var y_curve : Curve

@onready var hitbox = $Area2D 

var current_dash_count = 0

var is_direction_changed : bool

var time = 0
var target : BaseHero

var direction
var distance
var old_position
var curve_position

# Beethoven dashes forward piercing you and slashes towards you
# max length needed -> If the maximum length of this is reached, we do not extend further.

func _ready() -> void:
	hitbox.monitoring = false

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
	boss.hide_warning.emit()
	hitbox.monitoing = false

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
		
		if !is_direction_changed && time >= 0.25:
			is_direction_changed = true
			# Show hitbox
			hitbox.monitoring = true
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

func _on_area_2d_area_entered(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
		
	if !character: return 	# do not execute on non-characters or nulls
	character.take_damage(boss.char_stats.atk/boss.initial_atk * initial_dmg)
	character.add_status("Knockback", [250, global_position, 15])
	pass
