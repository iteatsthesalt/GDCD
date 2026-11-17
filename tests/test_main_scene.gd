extends GutTest
## Smoke tests for the entry scene. Keep these passing as the game grows.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"


func test_main_scene_is_configured() -> void:
	var configured: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_true(ResourceLoader.exists(configured), "run/main_scene must point at a real scene")


func test_main_scene_instantiates() -> void:
	var packed: PackedScene = load(MAIN_SCENE_PATH)
	var main: Node = add_child_autofree(packed.instantiate())
	assert_not_null(main)
	assert_eq(main.name, "Main")
