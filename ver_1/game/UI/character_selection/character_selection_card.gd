extends Panel

signal client_selected(char_id : int)

func _ready() -> void:
	client_selected.connect(GameManager.Instance.on_character_selected)

func _on_button_button_down() -> void:
	client_selected.emit(get_index())
	pass
