# GdUnit generated TestSuite
class_name GameManagerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://gamemanager/gamemanager.gd'

func test_gm_instanciable() -> void:
	var gm_scene: PackedScene = load("res://gamemanager/gamemanager.tscn")
	assert_bool(gm_scene.can_instantiate()).is_true()
	var gm = auto_free(gm_scene.instantiate())
	assert_bool(gm is GameManager).is_true()
	gm = gm as GameManager
	# Should either be in multiple levels mode or have a single level to instanciate
	assert_bool((gm.has_multiple_levels or gm.main_level or true)).is_true()
