class_name Dummy
extends BaseEnemy

@onready var hitbox : Area2D = $HitBox

func _init() -> void:
	super()
	pass

func _enter_tree() -> void:
	_init_stats()

func _init_stats() -> void:
	char_stats.maxhp = 10000
	char_stats.spd = 0
	char_stats.atk = 0
	current_health = char_stats.maxhp
	

func _ready() -> void:
	super()
	sprite = $Sprite2D
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

func take_damage(dmg) -> void:
	super(dmg)
	$TextPopUp.set_pop(str(dmg), self.global_position)
