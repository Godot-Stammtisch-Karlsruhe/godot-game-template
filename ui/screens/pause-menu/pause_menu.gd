extends Control

signal continue_btn_pressed
signal settings_btn_pressed
signal exit_to_main_menu_btn_pressed
signal exit_game_btn_pressed


func reset():
	%SettingsMenuPopup.hide()
	%MainPauseMenuPopup.show()
	
func _on_btn_continue_pressed():
	continue_btn_pressed.emit()
	hide()

func _on_btn_settings_pressed():
	settings_btn_pressed.emit()
	%SettingsMenuPopup.show()
	%MainPauseMenuPopup.hide()

func _on_btn_exit_to_main_menu_pressed():
	exit_to_main_menu_btn_pressed.emit()
	hide()

func _on_btn_exit_game_pressed():
	exit_game_btn_pressed.emit()
	hide()

func _on_save_and_back_btn_pressed():
	Settings.save_config()
	reset()


func _on_continue_btn_visibility_changed() -> void:
	if visible:
		$CenterContainer/MainPauseMenuPopup/VBoxContainer/ContinueBtn.grab_focus()
