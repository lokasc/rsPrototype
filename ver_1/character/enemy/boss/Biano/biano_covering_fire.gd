class_name BianoCoveringFire
extends BossAbility

### Biano shoots big bullets towards a target, activates only when Bee needs it or following up 

@export_category("Mechanics")
@export var projectile_scene : PackedScene
@export var p_dmg : float
@export var p_spd : float

@export var look_ahead_min : float = 50
@export var look_ahead_max : float = 60
@export var projectile_pause_time : float = 0.25

@export var projectile_scale : Vector2

var target : BaseHero
var type : int 
var rng = RandomNumberGenerator.new()
var count = 0

func _ready() -> void:
	super()

func enter() -> void:
	super()
	count = 0
	target = choose_player()
	$Timer.start(projectile_pause_time)
	
func exit() -> void:
	super() # starts cd here.
	$Timer.stop()

func update(_delta: float) -> void:
	super(_delta)


func physics_update(_delta: float) -> void:
	super(_delta)

func spawn_projectile(gpos : Vector2) -> void:
	var copy = projectile_scene.instantiate()
	
	copy.dmg = p_dmg
	copy.spd = p_spd
	copy.tile_scale = projectile_scale
	
	copy.initial_boss_atk = boss.initial_atk
	copy.boss_atk = boss.char_stats.atk
	
	copy.global_position = gpos
	
	var look_ahead = rng.randf_range(look_ahead_min, look_ahead_max)
	
	copy.look_at(target.global_position + target.velocity.normalized() * look_ahead)
	copy.rotate(deg_to_rad(270))
	
	GameManager.Instance.net.spawnable_path.call_deferred("add_child", copy, true)
	# spawn in network node.


func _on_timer_timeout() -> void:
	if count >= 2:
		$Timer.stop()
		state_change.emit(self, "BianoIdle")
	else:
		spawn_projectile(global_position)
		count += 1
