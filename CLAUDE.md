# CLAUDE.md

GDCD is a 2D game built with **Godot 4.7.2 (GDScript, no C#)**. It is developed mostly by
Claude Code in headless Linux cloud containers, with no Godot editor GUI. The owner often
works from a phone and can play the **Web build on GitHub Pages**
(https://iteatsthesalt.github.io/GDCD/). So everything must work headless, and the Web export
must keep working.

Status: the game is being moved here from an earlier Claude chat. Right now
`scenes/main.tscn` is a placeholder.

## Commands

| What | Command |
|---|---|
| Install Godot (pinned in `.godot-version`) | `tools/install_godot.sh` (`--web-templates` to export) |
| Install lint/format tools | `pip install "gdtoolkit==4.5.0"` |
| **Validate everything (run before every commit)** | `tools/check.sh` |
| Auto-format and validate | `tools/check.sh --fix` |
| Run unit tests only | `godot --headless --path . -s addons/gut/gut_cmdln.gd` |
| Run the game headless for N frames | `godot --headless --path . --quit-after 300` |
| Export the Web build to `build/web/` | `tools/export_web.sh` |
| Boot the Web build in Chromium and screenshot it | `node tools/web_smoke.js build/shot.png` |

`tools/check.sh` runs these steps in order: import (rebuilds `.godot/`), gdlint, gdformat check,
parse every script (`tools/validate_scripts.gd`), GUT tests, and booting the main scene. It
greps Godot's logs because **Godot often exits 0 even after script errors**. Never trust a
bare exit code from `godot`.

On a fresh clone, `.godot/` doesn't exist. Run `godot --headless --path . --import` (or
`tools/check.sh`) before anything else, or `class_name` types will fail to resolve.

To show the owner what the game looks like, run `tools/export_web.sh`, then
`node tools/web_smoke.js <png>`, then look at the screenshot.

## CI/CD

`.github/workflows/ci.yml` has three jobs:
- `check` runs `tools/check.sh`.
- `web` runs `tools/export_web.sh`.
- `deploy` publishes to GitHub Pages, on pushes to `main` only.

Keep CI green: if `tools/check.sh` passes locally, CI should too.

## Rules

- **Godot 4 only.** Training data is full of Godot 3 code. Check the cheat sheet below
  before writing GDScript.
- **Static typing everywhere.** Type `var x: int`, `func f(a: float) -> void:`, and
  `@onready var sprite: Sprite2D = $Sprite2D`. Use `:=` only when the type is obvious from the
  right-hand side.
- **Every gameplay change gets a test** in `tests/` (GUT, files named `test_*.gd`,
  `extends GutTest`). Keep `tests/test_main_scene.gd` passing.
- **Commit:**
  - `*.uid` files: Godot 4.4+ uses them to track resources.
  - `*.import` files.
  - `export_presets.cfg`. It contains no secrets.
- **Never commit:**
  - `.godot/` (cache)
  - `build/` (logs and exports)
- **Moving or renaming a file:** `git mv` the file *and* its `.uid` together. Then grep for
  the old `res://` path and update every reference.
- **Never copy a `.uid` file, or a `.tscn` header `uid=`, to a new file.** Duplicate UIDs
  break references. If it happens, delete the copied uid, `rm -rf .godot`, and re-import.
- `addons/gut/` is vendored GUT 9.7.1 (MIT). Don't edit it. GUT versions are tied to a
  Godot minor version (9.7.x supports Godot 4.7.x).
- The Web export must stay single-threaded (`variant/thread_support=false`). GitHub Pages
  can't send the COOP/COEP headers that threads need.
- The renderer is `gl_compatibility`, the only one that works on Web. Don't switch to
  Forward+/Mobile.
- Keep the game playable in a phone browser where practical (touch as well as mouse and
  keyboard). The owner often checks builds from Android.

## Editing scenes and resources as text

Prefer building scenes in code, or saving them via a headless script:
`PackedScene.pack()` + `ResourceSaver.save()`, run with
`godot --headless --path . --script res://path.gd`. Godot then writes valid files. If you
hand-edit `.tscn`/`.tres`:

- Header: `[gd_scene format=3]` (or `[gd_resource type="..." format=3]`). Don't write
  `load_steps`; it has been deprecated since 4.6.
- `uid=` attributes are optional. If you omit them, Godot falls back to `path`. Never invent
  one. Copy real ones from `foo.gd.uid` or the target scene's header.
- Leave out node `unique_id=`. Godot assigns it on save. Never duplicate one.
- `[ext_resource ... id="1_abc"]` is referenced as `ExtResource("1_abc")`. A
  `[sub_resource]` must come before anything that uses it.
- Node `parent` paths are relative to the root and don't include the root's name: `"."`,
  `"UI"`, `"UI/Center"`.
- After editing, run `tools/check.sh`. The scene smoke test catches broken references.

## Godot 3 → 4 cheat sheet (use the right-hand column)

| Godot 3 (wrong) | Godot 4 (right) |
|---|---|
| `tool`, `export var x`, `onready var` | `@tool`, `@export var x: int`, `@onready var` |
| `yield(obj, "sig")` | `await obj.sig` |
| `connect("s", self, "m")`, `emit_signal("s", a)` | `s.connect(m)`, `s.emit(a)` |
| `KinematicBody2D`, `move_and_slide(v, UP)` | `CharacterBody2D`, set `velocity`, then `move_and_slide()` |
| `scene.instance()` | `scene.instantiate()` |
| `rand_range`, `deg2rad`, `stepify`, `range_lerp` | `randf_range`/`randi_range`, `deg_to_rad`, `snapped`, `remap` |
| `get_tree().change_scene(p)` | `change_scene_to_file(p)` / `change_scene_to_packed(s)` |
| `File`, `Directory`, `OS.get_ticks_msec()`, `to_json` | `FileAccess`, `DirAccess`, `Time.get_ticks_msec()`, `JSON.stringify` |
| `setget` | `var x: int: set = _set_x, get = _get_x` |
| `Spatial`, `translation`, `Position2D`, `YSort` | `Node3D`, `position`, `Marker2D`, `y_sort_enabled` |
| `rect_size`, `rect_min_size`, `update()`, `.empty()` | `size`, `custom_minimum_size`, `queue_redraw()`, `is_empty()` |
| `PoolStringArray`, `Reference`, `BUTTON_LEFT` | `PackedStringArray`, `RefCounted`, `MOUSE_BUTTON_LEFT` |
| `Tween` node, `TileMap` | `create_tween()`, `TileMapLayer` |
| `remote`/`puppet`, `is_network_master()` | `@rpc`, `is_multiplayer_authority()` |

Also:
- Overridden lifecycle methods (`_ready`, ...) don't call the parent's version
  automatically. Call `super()`.
- `randomize()` runs automatically.

## Style (official GDScript style guide, enforced by gdlint)

- Tabs for indentation, lines of 100 characters or fewer, double quotes, and two blank
  lines between functions.
- Naming:
  - Files and folders: `snake_case`. Exported builds are case-sensitive.
  - `class_name` and node names: `PascalCase`.
  - Functions and variables: `snake_case`, with a `_private` prefix where private.
  - Signals: past tense (`health_changed`).
  - Constants and enum members: `CONSTANT_CASE`.
- Order inside a script: `@tool`, `class_name`, `extends`, `##` doc comment, signals, enums,
  constants, static vars, `@export` vars, vars, `@onready` vars, `_init`/`_ready`/`_process`,
  public methods, private methods.

## Layout

```
project.godot        engine config (main scene, display, renderer)
.godot-version       pinned Godot version (CI and tools read it)
scenes/              .tscn scenes, each with its script beside it (main.tscn + main.gd)
scripts/             standalone scripts: autoloads, resources, helpers
assets/              art, audio, fonts (keep their .import files)
tests/               GUT unit tests (test_*.gd); excluded from exports
tools/               headless dev scripts; excluded from exports
addons/gut/          vendored test framework; excluded from exports and lint
```

## Upgrading Godot

1. Change `.godot-version`.
2. Update `config/features` in `project.godot`.
3. Upgrade `addons/gut` to the GUT release for that minor version.
4. Run `tools/install_godot.sh --web-templates`, `tools/check.sh`, and `tools/export_web.sh`.
