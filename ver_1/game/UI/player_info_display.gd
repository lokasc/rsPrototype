class_name PlayerInfoDisplay
extends TextureProgressBar

# Handles the UI On top of the player.
@export var offset : Vector2 

var player : BaseHero
var is_bassheart : bool


@onready var health_bar : TextureProgressBar = self
@onready var shield_bar : TextureProgressBar = find_child("ShieldBar")
@onready var meter_bar : TextureProgressBar = find_child("MeterBar")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	meter_bar.visible = is_bassheart
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !player: return
	
	# Translate to screem space coordinate system
	global_position = player.get_screen_transform().origin.clamp(Vector2.ZERO, player.get_viewport_rect().size)
	global_position += offset
	
	# cap to 0	
	health_bar.value = max(0, player.current_health)
	shield_bar.value = player.current_shield
	
	if is_bassheart:
		meter_bar.value = player.meter

# set up the bar
func set_up(_player : BaseHero):
	player = _player
	
	# If its a bassheart
	if player.find_child("BassheartAttack"):
		is_bassheart = true
	else:
		is_bassheart = false
