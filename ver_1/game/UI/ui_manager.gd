class_name UIManager
extends Control

var my_player : BaseHero

@onready var card_scn = load("res://ver_1/game/UI/selection_card.tscn")
@onready var selection_container = $SelctionContainer
@onready var card_path = $SelctionContainer/HBox

@onready var health_bar = $HealthBar

var action_selected : bool

func _enter_tree() -> void:
	GameManager.Instance.ui = self
	GameManager.Instance.start_lvl_up_sequence.connect(build_selection_container)
	GameManager.Instance.end_lvl_up_sequence.connect(on_ready_to_continue)

func update_xp(xp : int):
	$LevelBar.value = xp
	pass

func _process(delta: float) -> void:
	if my_player:
		health_bar.value = my_player.current_health

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
	$SelctionContainer/Waiting.visible = true

func on_ready_to_continue():
	selection_container.visible = false
