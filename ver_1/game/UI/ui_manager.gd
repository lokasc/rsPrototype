class_name UIManager
extends Control

func _enter_tree() -> void:
	GameManager.Instance.ui = self

func update_xp(xp : int):
	$LevelBar.value = xp
	pass
