class_name BossHealthBarUI
extends TextureProgressBar

## How long for bar value to reach to max (At the start)
@export var time_to_full : float

@onready var boss_name_label : RichTextLabel = $BossName

var current_time : float = 0
var is_animating : bool
var is_started : bool = false # to make sure we modify health when in game.
var boss : BaseBoss

func _ready() -> void:
	visible = false

func set_up(_boss : BaseBoss):
	boss = _boss
	_boss.hit.connect(on_hit)
	_boss.die.connect(on_boss_die)
	max_value = boss.max_health
	value = 0
	is_animating = true
	is_started = true
	set_process(true)
	
	current_time = 0
	boss_name_label.text = "[b]" + "[center]"+ boss.char_name + "[/center]" +"[/b]"

func _process(delta: float) -> void:
	if is_animating:
		animation_logic(delta)
	
	if is_started && boss:
		value = boss.current_health

func animation_logic(delta):
	current_time += delta
	value = current_time/time_to_full * max_value
	if current_time >= time_to_full:
		is_animating = false

func on_hit(dmg):
	is_animating = false
	value = boss.current_health

func on_boss_die():
	set_process(false)
	boss = null
	visible = false
	
