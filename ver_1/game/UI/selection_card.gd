class_name SelectionCard
extends Button


signal client_card_selected(selected_card)

@onready var name_label = $VBoxContainer/Name as RichTextLabel
@onready var icon_texture = $VBoxContainer/TextureRect as TextureRect
@onready var status = $VBoxContainer/Status as RichTextLabel
@onready var desc = $VBoxContainer/Description as RichTextLabel

func _ready() -> void:
	self.client_card_selected.connect(GameManager.Instance.tell_server_client_is_ready)

func _on_button_down() -> void:
	GameManager.Instance.action_selected = true
	client_card_selected.emit(self)
