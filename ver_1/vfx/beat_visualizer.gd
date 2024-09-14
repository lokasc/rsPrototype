extends Control

@export var max_size : float
@export var min_size : float
@export var scaling_curve : Curve
@export var appearing_curve : Curve

var current_size : float
var completion_ratio : float # number between 0 - 1 determining how far along the journey is the animation, 0 is at the start of the journey, 1 is at the end
var time : float = 0


@onready var opaque_ring : TextureRect = $OpaqueRing
@onready var trans_ring : TextureRect = $TransparentRing
@onready var particles : GPUParticles2D = $GPUParticles2D
@onready var timer : Timer = $Timer

@onready var bc : BeatController = GameManager.Instance.bc
var time_til_next_beat: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TransparentRing.scale = max_size * Vector2.ONE
	#The beat does effects which give the illusion that the rings are arriving on time
	bc.on_beat.connect(end_opaque_ring)
	# Sets the particle colors equal to the transparent ring, without transparenncy
	particles.process_material.color = trans_ring.self_modulate
	particles.process_material.color.a = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_til_next_beat = bc.get_time_til_next_beat()
	completion_ratio = time_til_next_beat/0.5
	set_opaque_ring_alpha()
	set_opaque_ring_scale()


func set_opaque_ring_alpha() -> void:
	opaque_ring.self_modulate.a = appearing_curve.sample(completion_ratio)

#Technically its on beat at the beginning of the animation, not at the end, but it is masked by the end_opaque_ring func
func set_opaque_ring_scale() -> void:
	current_size = min_size + scaling_curve.sample(completion_ratio) * (max_size-min_size)
	if current_size >= max_size:
		current_size -= max_size-min_size
	opaque_ring.scale = current_size * Vector2.ONE

#Activates particles and changes trans ring colour to give the illusion
func end_opaque_ring() -> void:
	particles.restart()
	trans_ring.self_modulate.a = 0.8
	timer.start(0.1)

func _on_timer_timeout() -> void:
	trans_ring.self_modulate.a = 0.2
