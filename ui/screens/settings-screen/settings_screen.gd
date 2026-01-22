extends MarginContainer

signal exit()

func _ready():
	$VBoxContainer/Return.grab_focus()

func _return_to_title_screen() -> void:
	exit.emit()
	queue_free()
	Settings.save_config()
