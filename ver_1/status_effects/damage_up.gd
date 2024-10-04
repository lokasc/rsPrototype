class_name DamageUp
extends BaseStatus

var dmg_multiplier : float
var duration : float
var duration_time : float

#@onready var buff_sprite : CompressedTexture2D = load("res://assets/vfx/buffs/stressmarker.png")

var sprite_node : Sprite2D
var fade_speed : float = 0.5
var offset : Vector2 = Vector2(0,-55)

# Constructor, affects new() function for creating new copies
func _init(_dmg_multiplier : float, _duration : float) -> void:
	dmg_multiplier = _dmg_multiplier
	duration = _duration
	pass

func on_added() -> void:
	if character is BaseHero:
		#create_icon()
		character.char_stats.atk_mul *= dmg_multiplier
	duration_time = 0
	pass

func update(delta:float) -> void:
	duration_time += delta
	#sprite_node.self_modulate.a -= delta * duration_time
	#sprite_node.global_position.y -= delta * 40
	
	if duration_time >= duration:
		holder.remove_status(self)
	pass

func on_removed() -> void:
	if character is BaseHero:
		character.char_stats.atk_mul /= dmg_multiplier
		character.char_stats.atk_mul = max(1, character.char_stats.atk_mul)
		#sprite_node.queue_free()

func create_icon():
	sprite_node = Sprite2D.new()
	#sprite_node.texture = buff_sprite
	holder.add_child(sprite_node)
	sprite_node.position = offset
