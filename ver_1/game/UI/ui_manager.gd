class_name UIManager
extends Control

@export var player_container : Container
@export var selection_container : Container
@export var card_path : Container
@export var char_select_layer : CanvasLayer
@export var player_ui_layer : CanvasLayer
@export var player_info_scene : PackedScene
@export var player_info_container : Control

@export var card_scn : PackedScene

@onready var level_label : Label = player_container.find_child("Level")
@onready var level_bar : TextureProgressBar = player_container.find_child("LevelBar")
@onready var waiting_label : Label = player_container.find_child("Waiting")
@onready var time_label : Label = player_container.find_child("TimeLabel")

# Boss UI
@onready var boss_health_bar : BossHealthBarUI = player_ui_layer.find_child("BossHealthBarUI")
@onready var boss_health_bar_duo : BossHealthBarUI = player_ui_layer.find_child("BossHealthBarUI2")
@onready var cinematic_bars = player_ui_layer.find_child("CinematicBars")

# Abilities, Stats & Items
@onready var ability1 : AbilityBoxUI = player_container.find_child("Ability1")
@onready var ability2 : AbilityBoxUI = player_container.find_child("Ability2")

@onready var item1 : BaseBoxUI = player_container.find_child("Item1")
@onready var item2 : BaseBoxUI = player_container.find_child("Item2")
@onready var item3 : BaseBoxUI = player_container.find_child("Item3")
@onready var item4 : BaseBoxUI = player_container.find_child("Item4")

@onready var stat1 : BaseBoxUI = player_container.find_child("Stat1")
@onready var stat2 : BaseBoxUI = player_container.find_child("Stat2")
@onready var stat3 : BaseBoxUI = player_container.find_child("Stat3")
@onready var stat4 : BaseBoxUI = player_container.find_child("Stat4")

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
	boss_health_bar_duo.visible = false
	
	cinematic_bars.visible = false

func update_xp(xp : int):
	level_bar.value = xp

func update_max_xp(max_xp : int) -> void:
	level_bar.max_value = max_xp

func update_lvl_label(new_lvl : int) -> void:
	level_label.text = str(new_lvl)

func _process(_delta: float) -> void:
	var my_player = GameManager.Instance.local_player
	
	if GameManager.Instance.is_started:
		time_label.text = Time.get_time_string_from_unix_time(int(GameManager.Instance.time)).substr(3,5)
	
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

func create_player_info_bar(hero : BaseHero):
	var new_player_info = player_info_scene.instantiate() as PlayerInfoDisplay
	new_player_info.set_up(hero)
	player_info_container.add_child(new_player_info)

#region card selection ui
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

#endregion
#region actions display

func set_ability_ui():
	ability1.set_up(GameManager.Instance.local_player.ability_1)
	ability2.set_up(GameManager.Instance.local_player.ability_2)

func set_item_ui(_item : BaseItem, hero : BaseHero):
	if hero.multiplayer.get_unique_id() != hero.get_multiplayer_authority(): return
	
	# go through each item and see if they have an ability yet.
	var item_ui_slot : BaseBoxUI
	if !item1.action: item_ui_slot = item1
	elif !item2.action: item_ui_slot = item2
	elif !item3.action: item_ui_slot = item3
	elif !item4.action: item_ui_slot = item4
	else: 
		assert(1 < 0, "Error, no item ui slot found")
		return
	
	item_ui_slot.set_up(_item)

func set_stat_ui(_stat : BaseStatCard, hero : BaseHero):
	if hero.multiplayer.get_unique_id() != hero.get_multiplayer_authority(): return
	
	# go through each item and see if they have an ability yet.
	var stat_ui_slot : BaseBoxUI
	if !stat1.action: stat_ui_slot = stat1
	elif !stat2.action: stat_ui_slot = stat2
	elif !stat3.action: stat_ui_slot = stat3
	elif !stat4.action: stat_ui_slot = stat4
	else: 
		assert(1 < 0, "Error, no stat ui slot found")
		return
	
	stat_ui_slot.set_up(_stat)


#endregion

#region boss_ui
func set_boss_ui(_boss : BaseBoss):
	if boss_health_bar.boss:
		print("SECOND BOSS")
		boss_health_bar_duo.set_up(_boss)
		boss_health_bar_duo.visible = true
		return
	
	boss_health_bar.set_up(_boss)
	boss_health_bar.visible = true

@rpc("call_local", "reliable", "authority")
func stc_set_boss_ui(id : int):
	# get boss from id.
	var _boss = GameManager.Instance.spawner.get_enemy_from_id(id)
	set_boss_ui(_boss)

# Turns everything off in player container but the timer.
func turn_on_cinematic_bars(id):
	for x in player_ui_layer.get_children():
		x.visible = false
	cinematic_bars.visible = true
	boss_health_bar.visible = true
	if id == 22: boss_health_bar_duo.visible = true

func turn_off_cinematic_bars(id):
	for x in player_ui_layer.get_children():
		# do not turn on ability bars.
		if x is BeatVisualizer && x.is_lines:
			continue
		x.visible = true
	cinematic_bars.visible = false
	
	# turn off 2nd health bar if the beethoven isnt present.
	if id != 22: boss_health_bar_duo.visible = false
#endregion
