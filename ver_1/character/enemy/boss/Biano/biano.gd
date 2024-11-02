class_name Biano
extends BaseBoss

signal request_assistance
signal died

@export_subgroup("abilities")
@export var idle : BossAbility
@export var covering_fire : BossAbility
@export var rain : BossAbility # use BnBRain to switch due to file name
@export var escape : BossAbility

@export_subgroup("Stress Heuristic")
@export var cutoff : float # how much can I take. 
@export var hit_frequency : int # How many times I get hit consequetively.
@export var hit_time_frame : float # How long am I checking for?



# array and time stamps. 
# hm not actually too sure then here, ill have to think but its an array that leads to 
# I also want this to be exponential, ill have a think once i sit back down.

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

var ally : BaseBoss



func _enter_tree() -> void:
	super()
	char_id = 21
	assign_duo_boss()
	
func _ready() -> void:
	super()
	init_duo_signals()
	sprite = $Sprite2D
	x_scale = sprite.scale.x

# process your states here
func _process(delta: float) -> void:
	super(delta)
	
	if Input.is_action_just_pressed("attack"):
		request_assistance.emit()

#override this to add your states in 
func _init_states():
	_parse_abilities(idle)
	_parse_abilities(covering_fire)
	_parse_abilities(rain)
	_parse_abilities(escape)
	super()

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return

func assign_duo_boss():
	var other : BaseBoss = GameManager.Instance.spawner.get_enemy_from_id(22)
	# other hasn't loaded in, let other assign us. 
	if other == null: return
	#print("P",other.char_id)
	# assign for both
	other.ally = self
	ally = other

func try_follow_up():
	# maybe we want a heuristic? 
	# if we are in the falling biano state we cannot do it. 
	# Scope Creep: We can only do it if biano finishes firing the tiles.
	
	if current_state.name == "BianoEscapeFall": return
	state_change_from_any("BianoCoveringFire")

func on_request_assistance(): 
	pass

func init_duo_signals():
	if ally == null: return
	ally.zoning_strike.hit.connect(try_follow_up)
	ally.request_assistance.connect(on_request_assistance)
