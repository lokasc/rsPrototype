class_name SelectionCard
extends Control

signal client_card_selected(selected_card)
var action : BaseAction
var hero : BaseHero
var action_index : int

@onready var vbox : VBoxContainer = $VBoxContainer
@onready var name_label := $VBoxContainer/Name as RichTextLabel
@onready var icon_texture := $VBoxContainer/TextureRect as TextureRect
@onready var status := $VBoxContainer/Status as RichTextLabel
@onready var amount := $VBoxContainer/Amount as RichTextLabel
@onready var desc := $VBoxContainer/Description as RichTextLabel
@onready var button : Button = $Button

func _ready() -> void:
	self.client_card_selected.connect(GameManager.Instance.tell_server_client_is_ready)
	
	action = GameManager.Instance.action_list.get_new_class_script(action_index)
	
	name_label.text = "[center]" + action.action_name + "[/center]" 
	hero = GameManager.Instance.local_player
	
	desc.text = "[center]" + action.card_desc + "[/center]"
	icon_texture.texture = load(action.action_icon_path)
	
	amount.text = get_amount_string()
	status.text = get_status_string()

func _on_button_down() -> void:
	GameManager.Instance.action_selected = true
	client_card_selected.emit(action_index)
	action.queue_free()

func get_status_string() -> String:
	# why is this not nullable
	var _action : BaseAction = hero.get_action(action)
	if _action == null:
		return "[center] NEW! [/center]"
	
	# check level here
	if _action.level != 5:
		return "[center]" + "LVL:" + str(_action.level) + " to " + str(_action.level + 1) + "[/center]"
	else:
		return "[center]" + "Ascension" + "[/center]" 

func get_amount_string() -> String:
	var _action : BaseAction = hero.get_action(action)
	if _action == null:
		return "[center]" +  action.display_upgrade_amount + "[/center]"
	
	# check level here
	if _action.level != 5:
		return "[center]" +  action.display_upgrade_amount + "[/center]"
	else:
		return " " 
