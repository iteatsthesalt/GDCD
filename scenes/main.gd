extends Node2D
## Game entry point (run/main_scene). Swap the placeholder UI for the real game.


func _ready() -> void:
	print("GDCD booted on Godot %s" % Engine.get_version_info().string)
