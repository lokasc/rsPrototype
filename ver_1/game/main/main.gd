class_name Main
extends Node

@export var main_vbox : VBoxContainer
@export var play_options : VBoxContainer

@export var use_steam_button : CheckButton
@export var play_button : Button
@export var join_button : Button
@export var setting_button : Button
@export var quit_button : Button

@onready var gm_scene = preload("res://ver_1/game/main/game_manager.tscn")

var current_gm_scene
var in_play_options : bool
var in_join : bool
var in_settings : bool
var use_steam : bool

func reset():
	current_gm_scene.free()
	current_gm_scene = gm_scene.instantiate()
	add_child(current_gm_scene)

# This controls the entire application
func _ready() -> void:
	current_gm_scene = get_child(0)
	return
	hide_ui_at_start()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	use_steam = true

func _process(_delta) -> void:
	if Input.is_key_pressed(KEY_0):
		reset()

func hide_ui_at_start():
	in_play_options = false
	play_options.hide()

func reset_splash_default():
	in_play_options = false
	in_join = false
	in_settings = false
	
	play_button.modulate.a = 1
	join_button.modulate.a = 1
	setting_button.modulate.a = 1
	quit_button.modulate.a = 1
	play_options.hide()

func modulate_all_buttons():
	play_button.modulate.a = 0.4
	join_button.modulate.a = 0.4
	setting_button.modulate.a = 0.4
	quit_button.modulate.a = 0.4

# Show host or singleplayer (This will effect whether wait for player is on)
func _on_play_button_pressed() -> void:
	if in_play_options:
		reset_splash_default()
		return
	reset_splash_default()
	modulate_all_buttons()
	play_button.modulate.a = 1
	in_play_options = true
	play_options.show()

# show lobbies from friends?
func _on_join_button_pressed() -> void:
	if in_join:
		reset_splash_default()
		return
	
	reset_splash_default()
	modulate_all_buttons()
	join_button.modulate.a = 1
	in_join = true

func _on_settings_button_pressed() -> void:
	if in_settings:
		reset_splash_default()
		return
	
	reset_splash_default()
	modulate_all_buttons()
	setting_button.modulate.a = 1
	in_settings = true

func _on_quit_label_pressed() -> void:
	reset_splash_default()
	# quit, will not save local files.
	get_tree().quit()

func _on_steam_check_box_pressed() -> void:
	use_steam = !use_steam

# Create a lobby
func _on_host_button_pressed() -> void:
	pass

# Maybe you can instantiate here instead of doing something crazy.
func _on_sp_button_pressed() -> void:
	pass
