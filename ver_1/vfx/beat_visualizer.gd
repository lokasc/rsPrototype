extends Control

@export var max_size : float
@export var min_size : float
@export var time_to_max_size : float
@export var ring_path : Control
## the starting color of the moving ring
@export var starting_color : Color

## the ending color of the moving ring
@export var ending_color : Color

## the color of the particle effects
@export var particle_color : Color

## the color of the outer trans ring when NOT on beat
@export var transparent_color : Color

## the color of the outer trans ring when IT IS on beat
@export var beating_color : Color

var opaque_ring : Resource = preload("res://ver_1/vfx/opaque_ring.tscn")

@onready var trans_ring : TextureRect = $TransparentRing
@onready var particles : GPUParticles2D = $GPUParticles2D
@onready var effect_timer : Timer = $EffectTimer

@onready var bc : BeatController = GameManager.Instance.bc
var time_til_next_beat: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TransparentRing.scale = max_size * Vector2.ONE
	#The beat does effects which give the illusion that the rings are arriving on time
	bc.on_beat.connect(end_opaque_ring)
	bc.on_beat.connect(spawn_opaque_ring)
	
	particles.process_material.color = particle_color
	trans_ring.self_modulate = transparent_color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init_ring(ring : BeatTexture) -> void:
	ring.min_size = min_size
	ring.max_size = max_size
	ring.time_to_max_size = time_to_max_size
	ring.starting_color = starting_color
	ring.ending_color = ending_color

func spawn_opaque_ring() -> void:
	var new_ring = opaque_ring.instantiate()
	init_ring(new_ring)
	ring_path.add_child(new_ring)

#Activates particles and changes trans ring colour to give the illusion
func end_opaque_ring() -> void:
	particles.restart()
	trans_ring.self_modulate = beating_color
	effect_timer.start(bc.grace_time)

func _on_effect_timer_timeout() -> void:
	trans_ring.self_modulate = transparent_color
