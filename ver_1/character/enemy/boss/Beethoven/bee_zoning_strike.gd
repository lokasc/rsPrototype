class_name ZoningStrike
extends BossAbility

signal hit

@export var initial_dmg : float 
@export var wait_time : float = 0.3 # time before it starts to swing. (add in anim if possible)
@export var linger_time : float = 0.2 # How long the hitbox lasts.
var target : BaseHero

# Beethoven attacks in an arc, knocking any players away.

func _enter_tree() -> void:
	$Area2D.monitoring = false

func _ready() -> void:
	super()
	$Area2D.visible = false

func enter() -> void:
	super()
	target = choose_player()
	
	$Area2D.visible = false
	$WaitTimer.stop()
	$LingerTimer.stop()
	$WaitTimer.start(wait_time)


func _on_wait_timer_timeout() -> void:
	$Area2D.look_at(target.global_position)
	$Area2D.monitoring = true
	$LingerTimer.start(linger_time)
	$Area2D.visible = true

func _on_linger_timer_timeout() -> void:
	$Area2D.monitoring = false
	state_change.emit(self, "BeethovenIdle")
	$Area2D.visible = false

func update(delta) -> void:
	pass

func physics_update(delta) -> void:
	pass

func exit() -> void:
	$WaitTimer.stop()
	$LingerTimer.stop()
	$Area2D.visible = false
	$Area2D.monitoring = false

func _on_area_2d_area_entered(area: Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var character : BaseHero = null
	if area.get_parent() is BaseHero:
		character = area.get_parent()
		
	if !character: return 	# do not execute on non-characters or nulls
	character.take_damage(boss.char_stats.atk/boss.initial_atk * initial_dmg)
	character.add_status("Knockback", [250, global_position, 15])
