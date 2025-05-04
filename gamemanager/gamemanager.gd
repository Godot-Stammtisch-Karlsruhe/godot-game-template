extends Node
class_name GameManager

## Use this when you have only one level
@export var main_level: PackedScene
## Whether the mouse should be captured while in a level
@export var is_mouse_captured_in_level: bool = true

@export_subgroup("Level Loading")
## Whether your game contains multiple levels.
## Uncheck if you only have one "Level" in your game
## If disabled, no level select option will be given in the title screen
@export var has_multiple_levels: bool = true
## The number of the highest level. For 1 Level this is 1
@export var max_level: int = 0
## Formatable Strig pointing to
@export var level_location = "res://levels/level_%s.tscn"

@onready var pause_menu: Control = %PauseMenu
@onready var menu_layer: CanvasLayer = %MenuLayer

var level = 0
var completed_levels: Array[bool] = []
var current_level_node: Node

func _ready() -> void:
	Global.set_game_manager(self)
	DebugGlobal.debug_label = %DebugLabel
	for i in range(max_level): 
		completed_levels.append(false)
	# Load settings
	Settings.load_config()
	
	# Connect to InputManager
	InputManager.game_pause.connect(pause)
	InputManager.game_unpause.connect(resume)
	InputManager.set_is_in_game(false)
	InputManager.set_is_paused(false)
	
	_show_title_screen()
	
func _start_game() -> void:
	level = 0
	_show_controls()

#region Pausing

func pause():
	InputManager.set_is_paused(true)
	move_child(menu_layer, -1)
	pause_menu.move_to_front()
	pause_menu.show()
	get_tree().paused = true
	
func resume():
	InputManager.set_is_paused(false)
	print("resume")
	pause_menu.hide()
	pause_menu.reset()
	get_tree().paused = false
#endregion

#region Level Loading

func _show_main_level() -> void:
	InputManager.set_is_in_game(true)
	var next_level: Node = main_level.instantiate()
	InputManager.set_is_in_game(true)
	if next_level.has_signal("win"):
		next_level.win.connect(_next_level)
	if next_level.has_signal("reset"):
		next_level.reset.connect(_reload_current_level)
	add_child(next_level)
	current_level_node = next_level
	

func _next_level() -> void:
	if level < max_level and max_level > 0:
		InputManager.set_is_in_game(true)
		level += 1
		_show_level(level)
		completed_levels[level - 1] = true
	else: 
		_show_win_screen()

func _show_level(level_nr: int) -> void:
	InputManager.set_is_in_game(true)
	level = level_nr
	var next_level = load(level_location % str(level)).instantiate()
	if next_level.has_signal("win"):
		next_level.win.connect(_next_level)
	if next_level.has_signal("reset"):
		next_level.reset.connect(_reload_current_level)
	add_child(next_level)
	current_level_node = next_level
	
func _reload_current_level() -> void:
	# Destroy level
	if current_level_node != null:
		current_level_node.queue_free()
		current_level_node = null
	if has_multiple_levels:
		_show_level(level)
	else:
		_show_main_level()
#endregion

#region Showing Different GUI views 


func _show_win_screen() -> void:
	InputManager.set_is_in_game(false)
	var win_screen: Control = load("res://ui/screens/win-screen/win_screen.tscn").instantiate()
	win_screen.tree_exited.connect(_show_title_screen)
	add_child(win_screen)
	
func _show_credits() -> void:
	var credits: Node = load("res://ui/screens/credit-screen/credit_screen.tscn").instantiate()
	credits.tree_exited.connect(_show_title_screen)
	menu_layer.add_child(credits)
	
func _show_title_screen() -> void:
	InputManager.set_is_in_game(false)
	var title_screen: Node = load("res://ui/screens/title-screen/title_screen.tscn").instantiate()
	title_screen.start_game.connect(_start_game)
	title_screen.show_credits.connect(_show_credits)
	title_screen.show_level_select.connect(_show_level_select)
	title_screen.show_settings_screen.connect(_show_settings_screen)
	title_screen.quit.connect(_quit_game)
	title_screen.show_levels(has_multiple_levels)
	menu_layer.add_child(title_screen)

func _show_level_select() -> void:
	var level_select: Node = load("res://ui/screens/level-select-screen/level_select.tscn").instantiate()
	level_select.start_level.connect(_show_level)
	level_select.exit.connect(_show_title_screen)
	level_select.init_buttons(max_level, completed_levels)
	menu_layer.add_child(level_select)
	
func _show_settings_screen() -> void:
	var settings_screen: Node = load("res://ui/screens/settings-screen/settings_screen.tscn").instantiate()
	settings_screen.exit.connect(_show_title_screen)
	menu_layer.add_child(settings_screen)
	
func _show_controls() -> void:
	var controls: Node = load("res://ui/screens/control-screen/control_screen.tscn").instantiate()
	if not main_level:
		controls.tree_exited.connect(_next_level)
	else:
		controls.tree_exited.connect(_show_main_level)
	menu_layer.add_child(controls)

func _return_to_title_screen() -> void:
	get_tree().paused = false
	InputManager.set_is_paused(false)
	InputManager.set_is_in_game(false)
	# Destroy level
	if current_level_node != null:
		current_level_node.queue_free()
		current_level_node = null
	_show_title_screen()
#endregion

func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
	
func set_world_environment(env: Environment):
	$WorldEnvironment.environment = env
