extends Control

signal start_game()
signal show_credits()
signal show_level_select()
signal show_settings_screen()
signal quit()

func _ready():
	$CenterContainer2/VBoxContainer/Start.grab_focus()

func _on_start_pressed() -> void:
	start_game.emit()
	queue_free()

func _on_credit_pressed() -> void:
	show_credits.emit()
	queue_free()

func _on_level_select_pressed() -> void:
	show_level_select.emit()
	queue_free()
	
func _on_options_pressed() -> void:
	show_settings_screen.emit()
	queue_free()

func _on_quit_pressed():
	quit.emit()
	queue_free()

func show_levels(b: bool) -> void:
	$CenterContainer2/VBoxContainer/LevelSelect.visible = b
