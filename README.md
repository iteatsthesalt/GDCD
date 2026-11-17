# GDCD

Godot Claude CD: a 2D game made with [Godot 4.7](https://godotengine.org) and built with
Claude Code. Every push to `main` is tested and deployed as a playable Web build.

**Play:** https://iteatsthesalt.github.io/GDCD/ (after the one-time Pages setup below)

## One-time setup: GitHub Pages

1. Open **Settings → Pages**.
2. Under **Build and deployment → Source**, choose **GitHub Actions**.

The next push to `main` (or a manual run of the **CI** workflow) publishes the game.

## Working on it

With the Godot editor: open `project.godot` in Godot 4.7.x and press Play.

Headless, which is how Claude Code works on it:

```bash
tools/install_godot.sh             # installs the Godot version pinned in .godot-version
pip install "gdtoolkit==4.5.0"     # gdlint + gdformat
tools/check.sh                     # import, lint, format, parse, unit tests, boot
tools/export_web.sh                # Web build in build/web/
```

Tests use [GUT](https://github.com/bitwes/Gut) (vendored in `addons/gut`) and live in
`tests/`. See [CLAUDE.md](CLAUDE.md) for conventions, project layout and the Godot 4 cheat
sheet.

## CI/CD

`.github/workflows/ci.yml` runs on every push and pull request:

| Job | What it does |
|---|---|
| `check` | `tools/check.sh` |
| `web` | exports the Web build |
| `deploy` | publishes the Web build to GitHub Pages (`main` only) |
