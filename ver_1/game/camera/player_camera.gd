class_name PlayerCamera
extends Camera2D

## Controls the camera movement & effects. 
## Currently, it just follows the player.

@export var target : BaseHero #Assign the node this camera will follow.
@export var hide_off_screen : bool

@onready var visibility_notifier = $Area2D/CollisionShape2D

var _random_strength : float = 30# the max x,y and -x,-y the shake goes. 
var _shake_fade : float = 5 # how long each new shake fades off by delta
var cam_shake_rng = RandomNumberGenerator.new()

var is_shaking = false


func _process(delta:float) -> void:
	if !GameManager.Instance.is_game_started(): return
	
	# cam shake:
	if is_shaking:
		if _random_strength > 0:
			_random_strength -= delta * _shake_fade
			_random_strength = max(0, _random_strength)
			
			self.offset = randomOffset()
		else:
			is_shaking = false
			self.offset = Vector2.ZERO

func _ready():
	# connect signals if we have a target.
	if target:
		$Area2D.area_entered.connect(_on_area_2d_area_entered)
		$Area2D.area_exited.connect(_on_area_2d_area_exited)
		visibility_notifier.shape.size = Vector2(1280,720)

# May have to do the same to experience orbs
func _on_area_2d_area_entered(area: Area2D) -> void:
	if !target: return
	var enemy = area.get_parent()
	if (enemy is BaseEnemy || enemy is XpOrbs) && !enemy.visible:
		#if multiplayer.is_server(): print("Ive shown " + str(enemy))
		enemy.show()

func _on_area_2d_area_exited(area: Area2D) -> void:
	if !target: return
	var enemy = area.get_parent()
	if (enemy is BaseEnemy || enemy is XpOrbs) && hide_off_screen && enemy.visible:
		#if multiplayer.is_server(): print("Ive Hidden " + str(enemy))
		enemy.hide()

func start_shake(strength : float, fade : float) -> void:
	_random_strength = strength
	_shake_fade = fade
	
	is_shaking = true

func randomOffset() -> Vector2:
	return Vector2(cam_shake_rng.randf_range(-_random_strength, _random_strength), cam_shake_rng.randf_range(-_random_strength, _random_strength))
