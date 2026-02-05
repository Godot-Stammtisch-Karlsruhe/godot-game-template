extends TabContainer

@onready var action_remapping_button_scene: PackedScene = load("res://ui/components/settings-menu/action-remapping-button/action_remapping_button.tscn")

func _ready() -> void:
	call_deferred("_populate_menu")

func _populate_menu() -> void:
	var tab_idx = 0
	
	# Iterate through root categories (these become tabs)
	for root_category in Settings.get_root_categories():
		var margin_container = MarginContainer.new()
		add_child(margin_container)
		set_tab_title(tab_idx, root_category.display_text)
		
		var scroll_container = ScrollContainer.new()
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		margin_container.add_child(scroll_container)
		
		var margin_container2 = MarginContainer.new()
		margin_container2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin_container2.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_container.add_child(margin_container2)

		var cat_vbox = VBoxContainer.new()
		cat_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cat_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin_container2.add_child(cat_vbox)

		# Add subcategories as sections, and their settings
		_populate_category(cat_vbox, root_category, root_category.name)
		
		tab_idx += 1

## Recursively populate a category and its subcategories
## Subcategories become section headers, deeper ones are flattened
func _populate_category(container: VBoxContainer, category: Settings.SettingCategory, path_prefix: String, depth: int = 0) -> void:
	# If this is a subcategory (depth > 0), add a section header
	if depth > 0:
		var lbl_section_title = Label.new()
		lbl_section_title.text = category.display_text
		lbl_section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_section_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_section_title.theme_type_variation = "SettingsGroupLabel"
		container.add_child(lbl_section_title)
		container.add_child(HSeparator.new())
	
	# Add all settings in this category
	for setting in category.settings:
		_add_setting_ui(container, setting, path_prefix + "/" + setting.name)
	
	# Recursively add all subcategories
	for sub_category in category.sub_categories:
		var sub_path = path_prefix + "/" + sub_category.name
		_populate_category(container, sub_category, sub_path, depth + 1)

func _add_setting_ui(container: VBoxContainer, setting: Settings.Setting, setting_path: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 40)
	container.add_child(hbox)
	
	# Another HBoxContainer for the label and revert button
	var hbox_lbl = HBoxContainer.new()
	hbox_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(hbox_lbl)
	
	# Label for the name of the setting
	var lbl_name = Label.new()
	lbl_name.text = setting.display_text
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_lbl.add_child(lbl_name)
	
	# Revert button for changing the setting back to its default value
	# For input bindings a new button for each remapping is created later
	if not setting is Settings.InputRemappingSetting:
		var revert_btn = Button.new()
		revert_btn.icon = get_theme_icon("icon", "RevertButton")
		revert_btn.custom_minimum_size = Vector2(32, 32)
		revert_btn.theme_type_variation = "FlatButton"
		revert_btn.connect("pressed", func(): Settings.reset_value(setting_path))
		hbox_lbl.add_child(revert_btn)
		setting.value_changed.connect(func(__): _update_revert_button(setting_path, revert_btn))
		_update_revert_button(setting_path, revert_btn)

	# TODO: Tooltip
	
	# Setting-specific editor
	if setting is Settings.FloatSetting:
		var slider_setting = setting as Settings.FloatSetting
		var slider = HSlider.new()
		slider.min_value = slider_setting.min_value
		slider.max_value = slider_setting.max_value
		slider.step = slider_setting.step
		slider.value = slider_setting.value
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_FILL
		slider.connect("value_changed", setting.set_value)
		setting.value_changed.connect(slider.set_value_no_signal)
		hbox.add_child(slider)
	elif setting is Settings.OptionSetting:
		var dropdown_setting = setting as Settings.OptionSetting
		var option_button = OptionButton.new()
		for i in range(dropdown_setting.options.size()):
			option_button.add_item(dropdown_setting.options[i], i)
		# Find the index of the current value
		var current_idx = dropdown_setting.options.find(dropdown_setting.value)
		if current_idx >= 0:
			option_button.selected = current_idx
		option_button.connect("item_selected", func(idx: int): setting.set_value(dropdown_setting.options[idx]))
		setting.value_changed.connect(func(val): option_button.select(dropdown_setting.options.find(val)))
		hbox.add_child(option_button)
	elif setting is Settings.BoolSetting:
		var checkbox = CheckBox.new()
		checkbox.button_pressed = setting.value
		checkbox.connect("toggled", setting.set_value)
		setting.value_changed.connect(checkbox.set_pressed_no_signal)
		hbox.add_child(checkbox)
	elif setting is Settings.InputRemappingSetting:
		_add_input_remapping_ui(hbox, setting as Settings.InputRemappingSetting, setting_path)
	else:
		# Assume it's a basic boolean setting if it has a bool value
		if typeof(setting.value) == TYPE_BOOL:
			var checkbox = CheckBox.new()
			checkbox.button_pressed = setting.value
			checkbox.connect("toggled", setting.set_value)
			setting.value_changed.connect(checkbox.set_pressed_no_signal)
			hbox.add_child(checkbox)
		else:
			push_warning("Unknown setting type for: " + setting.display_text)

func _add_input_remapping_ui(hbox: HBoxContainer, setting: Settings.InputRemappingSetting, setting_path: String) -> void:
	var events = setting.value as Array[InputEvent]
	
	# First reset button
	var input_revert_btn_1 = Button.new()
	input_revert_btn_1.icon = get_theme_icon("icon", "RevertButton")
	input_revert_btn_1.custom_minimum_size = Vector2(32, 32)
	input_revert_btn_1.theme_type_variation = "FlatButton"
	input_revert_btn_1.connect("pressed", func(): Settings.reset_input_binding(setting_path, 0))
	hbox.add_child(input_revert_btn_1)
	setting.value_changed.connect(func(__): _update_input_mapping_revert_button(setting_path, 0, input_revert_btn_1))
	_update_input_mapping_revert_button(setting_path, 0, input_revert_btn_1)
	
	# First remapping button
	var remapping_btn1 = action_remapping_button_scene.instantiate()
	remapping_btn1.set_event(events[0] if events.size() > 0 else null)
	remapping_btn1.connect("action_changed", func(event: InputEvent): _keymap_changed(event, 0, setting_path))
	setting.value_changed.connect(func(value: Array[InputEvent]): _update_remapping_button(value, 0, remapping_btn1))
	hbox.add_child(remapping_btn1)

	# Second reset button
	var input_revert_btn_2 = Button.new()
	input_revert_btn_2.icon = get_theme_icon("icon", "RevertButton")
	input_revert_btn_2.custom_minimum_size = Vector2(32, 32)
	input_revert_btn_2.theme_type_variation = "FlatButton"
	input_revert_btn_2.connect("pressed", func(): Settings.reset_input_binding(setting_path, 1))
	hbox.add_child(input_revert_btn_2)
	setting.value_changed.connect(func(__): _update_input_mapping_revert_button(setting_path, 1, input_revert_btn_2))
	_update_input_mapping_revert_button(setting_path, 1, input_revert_btn_2)

	# Second remapping button
	var remapping_btn2 = action_remapping_button_scene.instantiate()
	remapping_btn2.set_event(events[1] if events.size() > 1 else null)
	remapping_btn2.connect("action_changed", func(event: InputEvent): _keymap_changed(event, 1, setting_path))
	setting.value_changed.connect(func(value: Array[InputEvent]): _update_remapping_button(value, 1, remapping_btn2))
	hbox.add_child(remapping_btn2)

func _keymap_changed(event: InputEvent, event_idx: int, setting_path: String) -> void:
	var events = Settings.get_value(setting_path).duplicate()
	if event_idx >= events.size():
		events.push_back(null)
	events[event_idx] = event
	print("Keymap changed " + str(event_idx) + ":" + str(events))
	Settings.set_value(setting_path, events)

func _update_revert_button(p_setting_path: String, button: Button) -> void:
	button.visible = not Settings.is_value_default(p_setting_path)

func _update_remapping_button(value: Array[InputEvent], index: int, btn: Button):
	btn.set_event(value[index] if value.size() > index else null)

func _update_input_mapping_revert_button(p_setting_path: String, index: int, button: Button) -> void:
	button.modulate = Color.WHITE if not Settings.is_input_binding_default(p_setting_path, index) else Color.TRANSPARENT
