extends Control

func _ready():
	$CenterContainer/VBoxContainer/Button.grab_focus()

func _on_button_pressed() -> void:
	queue_free()
