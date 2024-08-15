class_name Trebbie
extends BaseHero

func _enter_tree():
	super()
	pass

func _ready():
	super()

func _process(_delta):
	super(_delta)
	
	# TODO: Move this piece of code into trebbie's attack
	if input.is_use_mouse_auto_attack:
		basic_attack.look_at(input.mouse_pos)
	basic_attack.use_ability()

func _physics_process(_delta):
	super(_delta)

### Overide this to modify the starting stats of your hero
func _init_stats():
	super()
	char_stats.maxhp = 1000
	char_stats.spd = 700
	char_stats.aoe = 2
	char_stats.atk = 100
