extends Control

signal request_host
signal request_client()

func _on_join_button_down():
	request_client.emit()

func _on_host_button_down():
	request_host.emit()
	pass
