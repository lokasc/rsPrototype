class_name AbilityBoxUI
extends TextureRect

var ability : BaseAbility
var current_cd : float = 0
var is_on_cd : bool

@onready var description_container : Control = $DescriptionContainer
@onready var description_label : Label = $DescriptionContainer/DescriptionLabel
@onready var timer_label : Label = $RemainingTimeLabel

# Called by UI MANAGER
func set_up(_ability : BaseAbility):
	ability = _ability
	texture = load(ability.action_icon_path)
	ability.ability_used.connect(on_ability_used)
	ability.cooldown_finish.connect(on_cooldown_finish)

func _ready() -> void:
	# Rest everything first.
	description_container.visible = false
	on_cooldown_finish()

func _process(delta: float) -> void:
	# Dont get time if not on cd, save computation.
	if is_on_cd:
		current_cd = ability.a_stats.cd - ability.current_time
		
		if current_cd >= 1:
			# Turn it into an integer
			timer_label.text = "%d" % current_cd
		else:
			timer_label.text = "%.1f" % current_cd

# functions below are connected to abilities via signals
func on_cooldown_finish():
	is_on_cd = false
	self_modulate.a = 255
	timer_label.visible = false

func on_ability_used():
	is_on_cd = true
	current_cd = ability.a_stats.cd - ability.current_time
	self_modulate.a = 0.1
	timer_label.visible = true

#region Ability Info Hover
# when mouse enters the ability icon
func _on_mouse_entered() -> void:
	description_label.text = ability.desc
	description_container.visible = true

# when mouse exits the ability icon
func _on_mouse_exited() -> void:
	description_container.visible = false
#endregion
