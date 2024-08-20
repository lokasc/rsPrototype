class_name UIManager
extends Control

var my_player : BaseHero

@export var player_container : Container
@export var selection_container : Container
@export var card_path : Container

@onready var health_bar = player_container.find_child("HealthBar")
@onready var level_bar = player_container.find_child("LevelBar")
@onready var card_scn = load("res://ver_1/game/UI/selection_card.tscn")
@onready var waiting_label = player_container.find_child("Waiting")


var action_selected : bool

func _enter_tree() -> void:
	GameManager.Instance.ui = self
	GameManager.Instance.start_lvl_up_sequence.connect(build_selection_container)
	GameManager.Instance.end_lvl_up_sequence.connect(on_ready_to_continue)
	hide_ui()

func update_xp(xp : int):
	level_bar.value = xp
	pass

func _process(delta: float) -> void:
	if !my_player: return
	
	if my_player.is_alive():
		health_bar.value = my_player.current_health
	else:
		health_bar.value = 0

func hide_ui():
	visible = false

func show_ui():
	visible = true

func build_selection_container(info_array : Array):
	action_selected = false
	for n in card_path.get_children():
		card_path.remove_child(n)
		n.queue_free()
	
	selection_container.visible = true
	print(info_array.size())
	
	for action in info_array:
		var copy = card_scn.instantiate() as SelectionCard
		copy.client_card_selected.connect(on_client_selection)
		
		# TODO: Logic for filling in card details.
		
		card_path.add_child(copy,true)

# change ui when you've selected something
func on_client_selection(card_info):
	# disable all children
	for x in card_path.get_children():
		x.visible = false
	waiting_label.text = "Waiting for players"

func on_ready_to_continue():
	waiting_label.text = " "
	pass
