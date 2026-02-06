class_name UserDefinedSettings

enum DisplayMode {FULLSCREEN, WINDOWED_FULLSCREEN, WINDOWED}
enum AAMode_3D {DISABLED, FXAA, TAA, MSAA_2X, MSAA_4X, FSR_2}
enum AAMode_2D {DISABLED, MSAA_2X, MSAA_4X, MSAA_8X}

enum AudioBus {MASTER, MUSIC, SFX, VOICE}

func _register_settings() -> void:
	_register_graphics_settings()
	_register_audio_settings()
	_register_controls_settings()

func _register_graphics_settings() -> void:
	var graphics_category = Settings.SettingCategory.new("graphics", "Graphics")
	
	var display_mode_options: Array[String] = ["Fullscreen", "Windowed Fullscreen", "Windowed"]
	var display_mode_setting = Settings.OptionSetting.new("display_mode",
														"Display Mode",
														"Windowed Fullscreen",
														display_mode_options,
														_set_display_mode)
	graphics_category.add_setting(display_mode_setting)
	
	var vsync_enabled_setting = Settings.BoolSetting.new("vsync_enabled", "VSync enabled", true, _set_vsync_enabled)
	graphics_category.add_setting(vsync_enabled_setting)
	
	var aa_3d_options: Array[String] = ["Disabled", "FXAA", "TAA", "MSAA 2x", "MSAA 4x", "FSR 2"]
	var aa_3d_setting = Settings.OptionSetting.new("3d_aa_mode",
													"3D Anti-Aliasing Mode",
													"Disabled",
													aa_3d_options,
													_set_aa_mode_3d)
	graphics_category.add_setting(aa_3d_setting)
	
	# 2D MSAA is not yet available in the Compatibility renderer
	if (ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method") != "gl_compatibility"):
		var aa_2d_options: Array[String] = ["Disabled", "MSAA 2x", "MSAA 4x", "MSAA 8x"]
		var aa_2d_setting = Settings.OptionSetting.new("2d_aa_mode",
														"2D Anti-Aliasing Mode",
														"Disabled",
														aa_2d_options,
														_set_aa_mode_2d)
		graphics_category.add_setting(aa_2d_setting)
	
	Settings.add_root_category(graphics_category)

func _register_audio_settings() -> void:
	var audio_category = Settings.SettingCategory.new("audio", "Audio")
	
	var master_volume_setting = Settings.FloatSetting.new("volume_master",
														  "Master Volume",
														  100.0,
														  0.0,
														  150.0,
														  1.0,
														  func(volume): _set_audio_bus_volume(volume, AudioBus.MASTER))
	audio_category.add_setting(master_volume_setting)
	
	# Fine Control subcategory for audio
	var fine_control_category = Settings.SettingCategory.new("fine_control", "Fine Control")
	
	var music_volume_setting = Settings.FloatSetting.new("volume_music",
														 "Volume (Music)",
														 100.0,
														 0.0,
														 150.0,
														 1.0,
														 func(volume): _set_audio_bus_volume(volume, AudioBus.MUSIC))
	fine_control_category.add_setting(music_volume_setting)
	
	var sfx_volume_setting = Settings.FloatSetting.new("volume_sfx",
													   "Volume (SFX)",
													   100.0,
													   0.0,
													   150.0,
													   1.0,
													   func(volume): _set_audio_bus_volume(volume, AudioBus.SFX))
	fine_control_category.add_setting(sfx_volume_setting)
	
	var voice_volume_setting = Settings.FloatSetting.new("volume_voice",
														 "Volume (Voice)",
														 100.0,
														 0.0,
														 150.0,
														 1.0,
														 func(volume): _set_audio_bus_volume(volume, AudioBus.VOICE))
	fine_control_category.add_setting(voice_volume_setting)
	
	audio_category.add_sub_category(fine_control_category)
	
	Settings.add_root_category(audio_category)

func _register_controls_settings() -> void:
	var controls_category = Settings.SettingCategory.new("controls", "Controls")
	
	var mouse_sensitivity_setting = Settings.FloatSetting.new("mouse_sensitivity",
															  "Mouse Sensitivity",
															  1.0,
															  0.1,
															  1.9,
															  0.01)
	controls_category.add_setting(mouse_sensitivity_setting)
	
	var key_bindings_category = Settings.SettingCategory.new("key_bindings", "Key Bindings")
	
	# Insert remappable actions
	_create_action_setting(key_bindings_category, "move_up", "Move Forward")
	_create_action_setting(key_bindings_category, "move_down", "Move Backward")
	_create_action_setting(key_bindings_category, "move_left", "Move Left")
	_create_action_setting(key_bindings_category, "move_right", "Move Right")
	
	controls_category.add_sub_category(key_bindings_category)
	
	Settings.add_root_category(controls_category)


#region Graphics Settings Callbacks

func _set_display_mode(display_mode_string: String):
	var display_mode_index = ["Fullscreen", "Windowed Fullscreen", "Windowed"].find(display_mode_string)
	match display_mode_index:
		0: # FULLSCREEN
			Global.game_manager.get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		1: # WINDOWED_FULLSCREEN
			Global.game_manager.get_window().mode = Window.MODE_FULLSCREEN
		2: # WINDOWED
			Global.game_manager.get_window().mode = Window.MODE_WINDOWED

func _set_vsync_enabled(enabled: bool):
	var mode = DisplayServer.VSyncMode.VSYNC_ENABLED if enabled else DisplayServer.VSyncMode.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode) # Just for the main window

func _set_aa_mode_3d(mode_string: String):
	var mode_index = ["Disabled", "FXAA", "TAA", "MSAA 2x", "MSAA 4x", "FSR 2"].find(mode_string)
	var vp = Global.game_manager.get_viewport()
	vp.use_taa = false
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.msaa_2d = Viewport.MSAA_DISABLED
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	match mode_index:
		1: vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		2: vp.use_taa = true # TAA
		3: vp.msaa_3d = Viewport.MSAA_2X
		4: vp.msaa_3d = Viewport.MSAA_4X
		5: vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2

func _set_aa_mode_2d(mode_string: String):
	var mode_index = ["Disabled", "MSAA 2x", "MSAA 4x", "MSAA 8x"].find(mode_string)
	var vp = Global.game_manager.get_viewport()
	vp.msaa_2d = Viewport.MSAA_DISABLED
	match mode_index:
		1: vp.msaa_2d = Viewport.MSAA_2X # MSAA_2X
		2: vp.msaa_2d = Viewport.MSAA_4X # MSAA_4X
		3: vp.msaa_2d = Viewport.MSAA_8X # MSAA_8X

#endregion

#region Audio Settings Callbacks

func _set_audio_bus_volume(volume: float, bus: AudioBus):
	volume /= 100.0
	match bus:
		AudioBus.MASTER: AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), volume)
		AudioBus.MUSIC: AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), volume)
		AudioBus.SFX: AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), volume)
		AudioBus.VOICE: AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Voice"), volume)

#endregion

#region Control Settings Callbacks

func _create_action_setting(category: Settings.SettingCategory, action: String, label: String) -> void:
	var events = InputMap.action_get_events(action)
	var default_events: Array[InputEvent] = []
	for i in range(2):
		if i < events.size():
			default_events.append(events[i])
		else:
			default_events.append(null)

	var setting = Settings.InputRemappingSetting.new("action_map_" + action,
													label,
													default_events,
													func(new_events): _set_input_events(new_events, action))
	category.add_setting(setting)

func _set_input_events(events: Array[InputEvent], action: String) -> void:
	InputMap.action_erase_events(action)
	for event in events:
		if event:
			InputMap.action_add_event(action, event)
 
#endregion
