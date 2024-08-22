class_name TrebbieBuff
extends BaseAbility

@export var initial_cd : int
@export var initial_dur : float # duration of the ability applying the effect
@export var initial_hsg : float
@export var dmg_multiplier : float
@export var status_duration : float # duration of the status effects

var duration_time : float

@onready var hitbox : Area2D = $HitBox

# Initialize abilities
# WARNING: export variables wont be avaliable on init, use enter_tree
func _init() -> void:
	super()
	pass

# Initalize export variables, called before @onready or _ready()
# WARNING: Child nodes have not entered the tree yet. 
func _enter_tree() -> void:
	a_stats.cd = initial_cd
	a_stats.dur = initial_dur
	a_stats.hsg = initial_hsg
	pass

func _ready() -> void:
	hitbox.area_entered.connect(on_hit)
	hitbox.visible = false
	hitbox.monitoring = false

func enter() -> void:
	hitbox.visible = true
	hitbox.monitoring = true
	duration_time = 0 
	super()

func exit() -> void:
	super() # starts cd here.
	start_cd()
	hitbox.visible = false
	hitbox.monitoring = false

func update(delta: float) -> void:
	super(delta)
	duration_time += delta
	if duration_time >= initial_dur:
		state_change.emit(self, "TrebbieAttack")

func physics_update(_delta: float) -> void:
	super(_delta)
	if hero.input.direction:
		hero.velocity = hero.input.direction * hero.char_stats.spd
	else:
		hero.velocity = hero.velocity.move_toward(Vector2.ZERO, hero.DECELERATION)
	hero.move_and_slide()

	pass

# Call this to start cooldown.
func start_cd() -> void:
	super()

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
	
	# typecasting
	var character = area.get_parent() as BaseHero
	if character == null: return
	
	character.add_status("DamageUp", [dmg_multiplier, status_duration])

# Increments level by 1, override virtual func to change upgrade logic.
func _upgrade() -> void:
	super()

# Called automatically when ability cd finishes, override this to addd functionality when cd finishes
func _on_cd_finish() -> void:
	_reset()

# Resets ability, lets players to use it again, override this to add functionality.
func _reset() -> void:
	super()
