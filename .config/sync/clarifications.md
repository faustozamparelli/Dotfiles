# Sync clarifications

Open:

- None for now.

Findings:

- `Qwen`: no reliable desktop Homebrew cask found. Keep it as this-Mac-only.
- `Solves`: installed through the App Store. Remind Fausto to install it manually on other Macs.
- `fish_variables`: never sync as-is. It contains secrets and machine-specific PATH state.
- Local-only developer tools stay local: `cmake`, `go`, `graphviz`, `hugo`, `jupyterlab`, `openjdk`, `rust`, `typst`.
- Rectangle Pro: Fausto exported the config. Remind him to import/update it manually on other Macs.
- Shottr: Fausto exported the settings. Remind him to import/update them manually on other Macs.
- Codex/current agent: syncs by default. No tracked config needed.
- VS Code extension sync uses `~/.config/sync/vscode-extensions.txt` as shared desired state. Per-Mac inventory does not need extension lists because extensions should be the same at all times. Last pushed Mac wins when two Macs changed extensions independently. Per-Mac sync markers live under `~/.config/sync/state/<mac-name>/`.
