class_name BaseBoxUI
extends TextureRect

## This script handles player UI of stats and items. 
# TODO: Merge with ability_box and create functionality for cd based items.

var action : BaseAction
var current_cd : float = 0
var is_on_cd : bool

@onready var description_container : Control = $DescriptionContainer
@onready var description_label : RichTextLabel = $DescriptionContainer/DescriptionLabel
@onready var timer_label : Label = $RemainingTimeLabel
@onready var panel : Panel = $DescriptionContainer/Panel

# Called by UI MANAGER
func set_up(_action : BaseAction):
	action = _action
	texture = load(action.action_icon_path)

func _ready() -> void:
	# Rest everything first.
	description_container.visible = false
	on_cooldown_finish()

func _process(delta: float) -> void:
	# Dont get time if not on cd, save computation.
	pass
	#if is_on_cd:
		#current_cd = ability.a_stats.cd - ability.current_time
		#
		#if current_cd >= 1:
			## Turn it into an integer
			#timer_label.text = "%d" % current_cd
		#else:
			#timer_label.text = "%.1f" % current_cd

#region CD display
# functions below are connected to abilities via signals
func on_cooldown_finish():
	is_on_cd = false
	self_modulate.a = 255
	timer_label.visible = false

func on_ability_used():
	is_on_cd = true
	current_cd = action.a_stats.cd - action.current_time
	self_modulate.a = 0.1
	timer_label.visible = true
#endregion CD display

#region Ability Info Hover
# when mouse enters the ability icon
func _on_mouse_entered() -> void:
	if !action: return
	
	description_label.text = "[center]" + action.desc + "[/center]"
	panel.size = description_label.size
	panel.position = description_label.position
	description_container.visible = true

# when mouse exits the ability icon
func _on_mouse_exited() -> void:
	if !action: return
	description_container.visible = false
#endregion
