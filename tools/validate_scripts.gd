extends SceneTree
## Parses and compiles every GDScript in the project so syntax/type errors
## surface headlessly. Exits non-zero if any script fails.
##
## Usage: godot --headless --path . --script res://tools/validate_scripts.gd

const SKIP_DIRS: Array[String] = ["res://.godot", "res://addons", "res://build"]


func _initialize() -> void:
	var paths := _collect_scripts("res://")
	# Never reload the script that is currently running (crashes the VM).
	paths.erase(get_script().resource_path)
	var failed: Array[String] = []
	for path in paths:
		var script := (
			ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		)
		if script == null or not (script.can_instantiate() or script.is_abstract()):
			failed.append(path)
	if failed.is_empty():
		print("validate_scripts: %d scripts OK" % paths.size())
		quit(0)
	else:
		for path in failed:
			printerr("validate_scripts: FAILED %s" % path)
		quit(1)


func _collect_scripts(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	if dir_path in SKIP_DIRS:
		return found
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".gd"):
			found.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		found.append_array(_collect_scripts(dir_path.path_join(sub)))
	return found
