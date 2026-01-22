extends Control

func _ready():
	$CenterContainer/MarginContainer/Continue.grab_focus()

func _on_continue_pressed() -> void:
	queue_free()
