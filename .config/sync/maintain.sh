#!/usr/bin/env bash
set -euo pipefail

sync_dir="${SYNC_DIR:-$HOME/.config/sync}"
bare=(git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME")
computer_name="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
safe_name="$(printf '%s' "$computer_name" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-')"
safe_name="${safe_name%-}"
inventory_dir="$sync_dir/inventory/$safe_name"
state_dir="$sync_dir/state/$safe_name"
desired_extensions="$sync_dir/vscode-extensions.txt"
legacy_extensions="$sync_dir/vscode-extensions.current.txt"
legacy_last_seen_desired_extensions="$sync_dir/vscode-extensions.last-desired.$safe_name.txt"
last_seen_desired_extensions="$state_dir/vscode-extensions.last-seen.txt"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$sync_dir" "$inventory_dir" "$state_dir"

"${bare[@]}" pull --ff-only

# Legacy migration from the first snapshot-only version of this sync folder.
if [[ ! -f "$desired_extensions" && -f "$legacy_extensions" ]]; then
  cp "$legacy_extensions" "$desired_extensions"
  rm -f "$legacy_extensions"
fi

if [[ ! -f "$last_seen_desired_extensions" && -f "$legacy_last_seen_desired_extensions" ]]; then
  cp "$legacy_last_seen_desired_extensions" "$last_seen_desired_extensions"
  rm -f "$legacy_last_seen_desired_extensions"
fi

{
  printf 'computer_name=%s\n' "$computer_name"
  printf 'inventory_name=%s\n' "$safe_name"
  printf 'hostname=%s\n' "$(hostname)"
  printf 'arch=%s\n' "$(uname -m)"
  sw_vers | sed 's/^[[:space:]]*//'
  printf 'brew_prefix=%s\n' "$(brew --prefix)"
  printf 'brew_version=%s\n' "$(brew --version | head -n 1)"
} > "$inventory_dir/system.txt"

brew leaves | LC_ALL=C sort > "$inventory_dir/brew-leaves.txt"
brew list --cask | LC_ALL=C sort > "$inventory_dir/brew-casks.txt"
find /Applications -maxdepth 1 -name "*.app" -print 2>/dev/null \
  | sed 's#^.*/##; s#\.app$##' \
  | grep -v '^\.' \
  | LC_ALL=C sort > "$inventory_dir/applications.txt"

if command -v mas >/dev/null 2>&1; then
  mas list > "$inventory_dir/app-store.txt"
else
  rm -f "$inventory_dir/app-store.txt"
fi

if command -v code >/dev/null 2>&1; then
  current_extensions="$tmp_dir/vscode-current.txt"
  code --list-extensions | LC_ALL=C sort > "$current_extensions"

  if [[ ! -f "$desired_extensions" ]]; then
    cp "$current_extensions" "$desired_extensions"
    echo "Initialized shared VS Code extension list from this Mac."
  fi

  local_changed=false
  desired_changed=false

  if [[ -f "$last_seen_desired_extensions" ]] && ! cmp -s "$current_extensions" "$last_seen_desired_extensions"; then
    local_changed=true
  fi

  if [[ -f "$last_seen_desired_extensions" ]] && ! cmp -s "$desired_extensions" "$last_seen_desired_extensions"; then
    desired_changed=true
  fi

  if cmp -s "$current_extensions" "$desired_extensions"; then
    :
  elif [[ "$local_changed" == true ]]; then
    # Last-push-wins: local add/remove since last maintenance becomes the new
    # shared extension set, even if another Mac also changed the shared list.
    cp "$current_extensions" "$desired_extensions"
    echo "Adopted this Mac's VS Code extensions as the shared list."
  else
    # No local extension change: enforce the shared desired list from another
    # Mac, including uninstalling extensions removed from that list.
    missing_extensions="$tmp_dir/vscode-missing.txt"
    extra_extensions="$tmp_dir/vscode-extra.txt"
    comm -13 "$current_extensions" "$desired_extensions" > "$missing_extensions"
    comm -23 "$current_extensions" "$desired_extensions" > "$extra_extensions"

    while IFS= read -r extension; do
      [[ -z "$extension" ]] && continue
      code --install-extension "$extension"
    done < "$missing_extensions"

    while IFS= read -r extension; do
      [[ -z "$extension" ]] && continue
      code --uninstall-extension "$extension"
    done < "$extra_extensions"

    code --list-extensions | LC_ALL=C sort > "$current_extensions"
  fi

  cp "$desired_extensions" "$last_seen_desired_extensions"
else
  echo "VS Code CLI not found; skipped extension sync."
fi

"${bare[@]}" add \
  .config/sync \
  .config/karabiner/karabiner.json \
  ".config/fish/config.fish" \
  ".config/fish/functions/sync-maintain.fish" \
  ".config/fish/fish_plugins" \
  ".config/git/.gitconfig" \
  ".config/git/.gitignore" \
  ".config/ghostty/config" \
  ".config/ghostty/themes" \
  ".config/micro/bindings.json" \
  ".config/micro/colorschemes" \
  ".config/micro/settings.json" \
  ".zshrc" \
  ".gitconfig" \
  "Library/Application Support/Code/User/settings.json" \
  "Library/Application Support/Code/User/keybindings.json"

"${bare[@]}" status --short
