class_name UIManager
extends Control

@export var player_container : Container
@export var selection_container : Container
@export var card_path : Container
@export var char_select_layer : CanvasLayer
@export var player_ui_layer : CanvasLayer

@onready var health_bar : TextureProgressBar = player_container.find_child("HealthBar")
@onready var shield_bar : TextureProgressBar = player_container.find_child("ShieldBar")
@onready var level_label : Label = health_bar.get_child(0)
@onready var level_bar : TextureProgressBar = player_container.find_child("LevelBar")
@onready var card_scn : PackedScene = load("res://ver_1/game/UI/selection_card.tscn")
@onready var waiting_label : Label = player_container.find_child("Waiting")
@onready var time_label : Label = player_container.find_child("TimeLabel")

# Boss UI
@onready var boss_health_bar : BossHealthBarUI = $PlayerUi/PlayerContainer/BossHealthBarUI
# Abilities, Stats & Items
@onready var ability1 : AbilityBoxUI = $PlayerUi/PlayerContainer/ActionContainers/Ability1
@onready var ability2 : AbilityBoxUI = $PlayerUi/PlayerContainer/ActionContainers/Ability2

var action_selected : bool

func _enter_tree() -> void:
	GameManager.Instance.ui = self
	GameManager.Instance.start_lvl_up_sequence.connect(build_selection_container)
	GameManager.Instance.end_lvl_up_sequence.connect(on_ready_to_continue)
	hide_ui()

func _ready() -> void:
	hide_character_select()
	hide_player_ui()
	update_max_xp(GameManager.Instance.max_xp)
	boss_health_bar.visible = false

func update_xp(xp : int):
	level_bar.value = xp

func update_max_xp(max_xp : int) -> void:
	level_bar.max_value = max_xp

func update_lvl_label(new_lvl : int) -> void:
	level_label.text = str(new_lvl)

func _process(_delta: float) -> void:
	var my_player = GameManager.Instance.local_player
	if !my_player: return
	
	if my_player.is_alive():
		health_bar.value = my_player.current_health
		shield_bar.value = my_player.current_shield
	else:
		health_bar.value = 0
	
	if GameManager.Instance.is_started:
		time_label.text = Time.get_time_string_from_unix_time(GameManager.Instance.time).substr(3,5)
	
	# Uncomment this if you want the shield to change rotation along the health bar
	#var shield_init_angle = health_bar.value/health_bar.max_value * 360
	#shield_bar.radial_initial_angle = -shield_init_angle

func hide_ui():
	visible = false

func show_ui():
	visible = true

func show_character_select():
	char_select_layer.visible = true

func hide_character_select():
	char_select_layer.visible = false

func show_player_ui():
	player_ui_layer.visible = true

func hide_player_ui():
	player_ui_layer.visible = false


# called by the game_manager
func build_selection_container(info_array : Array):
	action_selected = false
	for n in card_path.get_children():
		card_path.remove_child(n)
		n.queue_free()
	
	selection_container.visible = true
	
	for action_index in info_array:
		var copy := card_scn.instantiate() as SelectionCard
		copy.client_card_selected.connect(on_client_selection)
		copy.action_index = action_index
		card_path.add_child(copy,true)

# change ui when you've selected something
func on_client_selection(_card_info):
	# disable all children
	for x in card_path.get_children():
		x.visible = false
	waiting_label.text = "Waiting for players"

func on_ready_to_continue():
	waiting_label.text = " "
	pass

func set_ability_ui():
	ability1.set_up(GameManager.Instance.local_player.ability_1)
	ability2.set_up(GameManager.Instance.local_player.ability_2)

func set_boss_ui(_boss : BaseBoss):
	boss_health_bar.set_up(_boss)
	boss_health_bar.visible = true

@rpc("call_local", "reliable", "authority")
func stc_set_boss_ui(id : int):
	# get boss from id.
	var _boss = GameManager.Instance.spawner.get_enemy_from_id(id)
	set_boss_ui(_boss)
