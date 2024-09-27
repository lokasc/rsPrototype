class_name Beethoven
extends BaseBoss

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

@export var idle : BossAbility
@export var sting : BossAbility 
@export var pump_fake : BossAbility
@export var dash : BossAbility


func _enter_tree() -> void:
	super()
	char_id = 22

func _ready() -> void:
	super()
	sprite = $Sprite2D
	x_scale = sprite.scale.x

# process your states here
func _process(delta: float) -> void:
	if frozen: return
	
	super(delta)

func _physics_process(delta : float) -> void:
	if frozen: return
	super(delta)
	
	
#override this to add your states in 
func _init_states():
	_parse_abilities(idle)
	_parse_abilities(sting)
	_parse_abilities(pump_fake)
	_parse_abilities(dash)
	super()

func on_hit(area : Area2D) -> void:
	if !multiplayer.is_server(): return
