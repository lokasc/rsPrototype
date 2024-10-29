class_name BianoCoveringFire
extends BossAbility

### Biano shoots big bullets towards a target, activates only when Bee needs it or following up 

@export_category("Mechanics")
@export var projectile_scene : PackedScene
@export var p_dmg : float
@export var p_spd : float

@export var projectile_scale : Vector2

var target : BaseHero
var type : int 

func _ready() -> void:
	super()

func enter() -> void:
	super()
	target = choose_player()
	spawn_projectile(global_position)
	
func exit() -> void:
	super() # starts cd here.

func update(_delta: float) -> void:
	super(_delta)
	state_change.emit(self, "BianoIdle")


func physics_update(_delta: float) -> void:
	super(_delta)

func spawn_projectile(gpos : Vector2) -> void:
	var copy = projectile_scene.instantiate()
	
	copy.dmg = p_dmg
	copy.spd = p_spd
	
	copy.initial_boss_atk = boss.initial_atk
	copy.boss_atk = boss.char_stats.atk
	
	copy.global_position = gpos
	copy.look_at(target.global_position)
	copy.rotate(deg_to_rad(270))
	
	GameManager.Instance.net.spawnable_path.add_child(copy, true)
	# spawn in network node.
