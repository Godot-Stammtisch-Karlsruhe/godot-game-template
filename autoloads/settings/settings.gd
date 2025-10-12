extends Node

#region Helper enums and data classes

class SettingCategory:
	var name: String
	var display_text: String

	var sub_categories: Array[SettingCategory] = []
	var settings: Array[Setting] = []

	func _init(p_name: String, p_display_text: String = ""):
		name = p_name
		display_text = p_display_text if p_display_text != "" else p_name
	
	func add_setting(p_setting: Setting) -> void:
		if OS.is_debug_build() and settings.filter(func(s): return s.name == p_setting.name).size() > 0:
			push_warning("Setting " + p_setting.name + " already exists in category " + name)
			return
		settings.append(p_setting)

	func add_sub_category(p_category: SettingCategory) -> void:
		if OS.is_debug_build() and sub_categories.filter(func(c): return c.name == p_category.name).size() > 0:
			push_warning("Sub-category " + p_category.name + " already exists in category " + name)
			return
		sub_categories.append(p_category)
	
	func get_setting(p_name: String) -> Setting:
		for setting in settings:
			if setting.name == p_name:
				return setting
		push_warning("Setting " + p_name + " not found in category " + name)
		return null
	
	func get_sub_category(p_name: String) -> SettingCategory:
		for category in sub_categories:
			if category.name == p_name:
				return category
		push_warning("Sub-category " + p_name + " not found in category " + name)
		return null

@abstract
class Setting:
	signal value_changed(value: Variant)
	var name: String
	var display_text: String
	var value: Variant:
		set = set_value
	var default_value: Variant
	var requires_restart: bool
	var setter_callable: Callable

	func _init(p_name: String, p_display_text: String, p_default_value: Variant, p_setter_callable: Callable = Callable(), p_requires_restart: bool = false):
		self.name = p_name
		self.display_text = p_display_text
		self.value = p_default_value
		self.default_value = p_default_value
		self.setter_callable = p_setter_callable
		self.requires_restart = p_requires_restart
	
	func set_value(p_value: Variant):
		if not is_same(p_value, value):
			value = p_value
			value_changed.emit(value)
			if setter_callable.is_valid():
				setter_callable.call(value)

class OptionSetting extends Setting:
	var options: Array[String]

	func _init(p_name: String, p_label_text: String, p_default_value: String, p_options: Array[String], p_setter_callable: Callable = Callable(), p_requires_restart: bool = false):
		assert(p_options.has(p_default_value))
		self.options = p_options
		super(p_name, p_label_text, p_default_value, p_setter_callable, p_requires_restart)

class FloatSetting extends Setting:
	var min_value: float
	var max_value: float
	var step: float
	func _init(p_name: String, p_label_text: String, p_default_value: float, p_min: float, p_max: float, p_step: float, p_setter_callable: Callable = Callable(), p_requires_restart: bool = false):
		assert(p_default_value >= p_min and p_default_value <= p_max)
		self.min_value = p_min
		self.max_value = p_max
		self.step = p_step
		super(p_name, p_label_text, p_default_value, p_setter_callable, p_requires_restart)

class BoolSetting extends Setting:
	func _init(p_name: String, p_label_text: String, p_default_value: bool, p_setter_callable: Callable = Callable(), p_requires_restart: bool = false):
		super(p_name, p_label_text, p_default_value, p_setter_callable, p_requires_restart)

class InputRemappingSetting extends Setting:
	var actions: Array[InputEvent]
	func _init(p_name: String, p_label_text: String, p_default_value: Array[InputEvent], p_setter_callable: Callable = Callable(), p_requires_restart: bool = false):
		super(p_name, p_label_text, p_default_value, p_setter_callable, p_requires_restart)
		self.actions = p_default_value.duplicate()


#endregion

#region Settings interface

## Stores all settings in a hierarchical structure
var _root_categories: Array[SettingCategory] = []

## Adds a new root category which can be populated with settings and sub-_root_categories.
func add_root_category(p_setting_category: SettingCategory) -> void:
	if _root_categories.filter(func(c): return c.name == p_setting_category.name).size() > 0:
		push_warning("Category " + p_setting_category.name + " does already exist")
		return
	_root_categories.append(p_setting_category)

func get_root_categories() -> Array[SettingCategory]:
	return _root_categories

func get_root_category(p_name: String) -> SettingCategory:
	for category in _root_categories:
		if category.name == p_name:
			return category
	push_warning("Category " + p_name + " not found")
	return null
 
## Gets the value of a setting by path (e.g., "Category/SubCategory/SettingName")
func get_value(p_path: String) -> Variant:
	var setting = _get_setting_by_path(p_path)
	if setting:
		return setting.value
	push_warning("Setting " + p_path + " not found")
	return null

## Sets the value of a setting by path (e.g., "Category/SubCategory/SettingName")
func set_value(p_path: String, p_value: Variant) -> void:
	var setting = _get_setting_by_path(p_path)
	if setting:
		if typeof(p_value) != typeof(setting.default_value):
			push_warning("Variant type mismatch for setting " + p_path + " (" + type_string(typeof(p_value)) + " should be " + type_string(typeof(setting.default_value)) + ")")
			return
		setting.value = p_value
	else:
		push_warning("Setting " + p_path + " not found")

## Sets the default value of a setting by path (e.g., "Category/SubCategory/SettingName")
func set_default_value(p_path: String, p_default_value: Variant) -> void:
	var setting = _get_setting_by_path(p_path)
	if setting:
		if typeof(p_default_value) != typeof(setting.default_value):
			push_warning("Variant type mismatch for setting " + p_path + " (" + type_string(typeof(p_default_value)) + " should be " + type_string(typeof(setting.default_value)) + ")")
			return
		setting.default_value = p_default_value
	else:
		push_warning("Setting " + p_path + " not found")

## Resets a setting to its default value by path (e.g., "Category/SubCategory/SettingName")
func reset_value(p_path: String):
	var setting = _get_setting_by_path(p_path)
	if setting:
		setting.value = setting.default_value
		if setting.setter_callable.is_valid():
			setting.setter_callable.call(setting.default_value)
	else:
		push_warning("Setting " + p_path + " not found")

## Resets a specific input binding at the given index to its default value
func reset_input_binding(p_path: String, index: int):
	var setting = _get_setting_by_path(p_path)
	if not setting:
		push_warning("Setting " + p_path + " not found")
		return
	
	if not setting is InputRemappingSetting:
		push_warning("Setting " + p_path + " is not an InputRemappingSetting")
		return
	
	var events = setting.value.duplicate() as Array[InputEvent]
	if index >= events.size():
		push_warning("Index " + str(index) + " out of bounds for input_binding setting " + p_path)
		return
	
	var default_event = setting.default_value[index] if index < setting.default_value.size() else null
	events[index] = default_event
	setting.value = events
	if setting.setter_callable.is_valid():
		setting.setter_callable.call(events)

## Checks if a setting's value equals its default value
func is_value_default(p_path: String) -> bool:
	var setting = _get_setting_by_path(p_path)
	if setting:
		return is_equal(setting.value, setting.default_value)
	push_warning("Setting " + p_path + " not found")
	return false

## Checks if a specific input binding at the given index equals its default value
func is_input_binding_default(p_path: String, index: int) -> bool:
	var setting = _get_setting_by_path(p_path)
	if not setting:
		push_warning("Setting " + p_path + " not found")
		return false
	
	if not setting is InputRemappingSetting:
		push_warning("Setting " + p_path + " is not an InputRemappingSetting")
		return false
	
	var event = setting.value[index] if index < setting.value.size() else null
	var default_event = setting.default_value[index] if index < setting.default_value.size() else null
	return is_equal(event, default_event)

## Helper function to find a setting by path (e.g., "Category/SubCategory/SettingName")
func _get_setting_by_path(p_path: String) -> Setting:
	var path_parts = p_path.split("/")
	if path_parts.size() < 2:
		push_warning("Invalid setting path: " + p_path + ". Expected format: 'Category/SettingName' or 'Category/SubCategory/.../SettingName'")
		return null
	
	# Find the root category
	var category = get_root_category(path_parts[0])
	if not category:
		return null
	
	# Traverse subcategories
	for i in range(1, path_parts.size() - 1):
		category = category.get_sub_category(path_parts[i])
		if not category:
			return null
	
	# Get the setting from the final category
	var setting_name = path_parts[path_parts.size() - 1]
	return category.get_setting(setting_name)


func save_config():
	var config = ConfigFile.new()

	for category in _root_categories:
		_save_category_recursive(config, category, category.name)

	var error = config.save("user://config.cfg")
	if error != OK:
		push_error("Failed to save config file: " + str(error))

## Recursively saves all settings in a category and its subcategories
func _save_category_recursive(config: ConfigFile, category: SettingCategory, section_path: String) -> void:
	# Save all settings in this category
	for setting in category.settings:
		config.set_value(section_path, setting.name, setting.value)
	
	# Recursively save all subcategories
	for sub_category in category.sub_categories:
		var sub_section_path = section_path + "/" + sub_category.name
		_save_category_recursive(config, sub_category, sub_section_path)

func load_config():
	var config = ConfigFile.new()
	var error = config.load("user://config.cfg")
	
	if error != OK:
		push_warning("Failed to load config file: " + str(error) + ". Using default values.")
		return

	for category in _root_categories:
		_load_category_recursive(config, category, category.name)
	
## Recursively loads all settings in a category and its subcategories
func _load_category_recursive(config: ConfigFile, category: SettingCategory, section_path: String) -> void:
	# Load all settings in this category
	for setting in category.settings:
		if not config.has_section_key(section_path, setting.name):
			push_warning("Setting " + setting.name + " not found in section " + section_path + ", using default value")
			continue
		
		var value = config.get_value(section_path, setting.name, setting.default_value)
		
		if typeof(value) != typeof(setting.default_value):
			push_warning("Variant type mismatch for setting " + setting.name + " (" + type_string(typeof(value)) + " should be " + type_string(typeof(setting.default_value)) + "), using default value")
			continue
		
		# TODO: Do something about this?
		# Set the value (this will trigger the setter and emit signals)
		setting.value = value
	
	# Recursively load all subcategories
	for sub_category in category.sub_categories:
		var sub_section_path = section_path + "/" + sub_category.name
		_load_category_recursive(config, sub_category, sub_section_path)

## Be cautious! Clears the config file, resetting all settings to their default values.
## This can be useful for troubleshooting.
func clear_config():
	var config = ConfigFile.new()
	config.save("user://config.cfg")

#endregion

## Deep property based equality check for two variants
func is_equal(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	if typeof(a) != TYPE_DICTIONARY and typeof(a) != TYPE_OBJECT and typeof(a) != TYPE_ARRAY:
		return a == b
	if typeof(a) == TYPE_ARRAY:
		if a.size() != b.size():
			return false
		for i in range(a.size()):
			if not is_equal(a[i], b[i]):
				return false
		return true
	if typeof(a) == TYPE_DICTIONARY:
		# Compare all keys of the two dictionaries
		for key in a.keys():
			if not b.has(key):
				return false
			if not is_equal(a[key], b[key]):
				return false
		for key in b.keys():
			if not a.has(key):
				return false
		return true
	# Both are objects, compare all properties
	for prop in a.get_property_list():
		if not is_equal(a.get(prop.name), b.get(prop.name)):
			return false
	return true
