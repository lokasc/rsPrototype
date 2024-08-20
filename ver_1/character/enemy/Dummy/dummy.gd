class_name Dummy
extends BaseEnemy

@onready var sprite : Sprite2D = $Sprite2D
@onready var hitbox : Area2D = $HitBox

func _init():
	super()
	pass

func _enter_tree():
	_init_stats()

func _ready() -> void:
	super()
	hitbox.area_entered.connect(on_hit)
	pass

func _process(delta: float) -> void:
	# display my health please thank u very much
	$Label.text = str(current_health)

func on_hit(area : Area2D):
	if !multiplayer.is_server(): return
	
	# typecasting
	var hero = area.get_parent() as BaseHero
	if hero == null: return
	
	# TODO: not networked yet
	# need to calculate how much damage based on 
	# the attack value of this ability + my character's attack value
	hero.take_damage(char_stats.atk)

func take_damage(dmg):
	super(dmg)
