class_name Beethoven
extends BaseBoss

signal show_warning(dir, seconds)
signal hide_warning

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

@export var idle : BossAbility
@export var sting : BossAbility 
@export var pump_fake : BossAbility
@export var dash : BossAbility

@export var indicator : Sprite2D

func _enter_tree() -> void:
	super()
	char_id = 22
	show_warning.connect(on_show_warning)
	hide_warning.connect(on_hide_warning)

func _ready() -> void:
	super()
	indicator.hide()
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

func on_show_warning(pos, seconds) -> void:
	indicator.show()
	indicator.look_at(pos)
	
	if seconds == 0: return
	$WarningTimer.start(seconds)

func on_hide_warning() -> void:
	indicator.hide()

func _on_warning_timer_timeout() -> void:
	indicator.hide()
	pass
