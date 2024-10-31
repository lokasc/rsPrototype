class_name Beethoven
extends BaseBoss

signal show_warning(dir, seconds)
signal hide_warning

signal request_assistance # asks Biano to start "covering fire"

@onready var hitbox : Area2D = $HitBox
@onready var collidebox : CollisionShape2D = $CollisionBox

@export var indicator : Sprite2D
@export_subgroup("abilities")
@export var idle : BossAbility
@export var zoning_strike : ZoningStrike 
@export var bodyguard : BeeBodyguard
@export var pump_fake : BossAbility
@export var dash : BossAbility

var ally : BaseBoss

func _enter_tree() -> void:
	super()
	char_id = 22
	assign_duo_boss()
	show_warning.connect(on_show_warning)
	hide_warning.connect(on_hide_warning)

func _ready() -> void:
	super()
	init_duo_signals()
	indicator.hide()
	sprite = $Sprite2D
	x_scale = sprite.scale.x

# process your states here
func _process(delta: float) -> void:
	super(delta)
	
	if Input.is_action_just_pressed("attack"):
		request_assistance.emit()

func _physics_process(delta : float) -> void:
	if frozen: return
	super(delta)

#override this to add your states in, executed in enter_tree
func _init_states():
	_parse_abilities(idle)
	_parse_abilities(zoning_strike)
	_parse_abilities(bodyguard)
	_parse_abilities(pump_fake)
	_parse_abilities(dash)
	super()


#region init
func assign_duo_boss():
	var other : BaseBoss = GameManager.Instance.spawner.get_enemy_from_id(21)
	# other hasn't loaded in, let other assign us. 
	if other == null: 
		print("cant find other unit")
		return
	#print("B",other.char_id)
	
	# assign for both
	other.ally = self
	ally = other


func init_duo_signals():
	if ally == null: return
	ally.request_assistance.connect(on_request_assistance)
	ally.init_duo_signals() # IMPORTANT: BIANO MUST SPAWN BEFORE BEETHOVEN

# Displays warning symbol when about to attack.
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
#endregion


func on_request_assistance():
	if current_state is BeeBodyguard: return
	
	state_change_from_any("BeeBodyguard")
