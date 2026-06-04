#!/usr/bin/env bash
set -euo pipefail

sync_dir="${SYNC_DIR:-$HOME/.config/sync}"
bare=(git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME")
computer_name="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
safe_name="$(printf '%s' "$computer_name" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-')"
safe_name="${safe_name%-}"
inventory_dir="$sync_dir/inventory/$safe_name"
state_dir="$sync_dir/state/$safe_name"
shared_dir="$sync_dir/shared"
shared_brew_leaves="$shared_dir/brew-leaves.txt"
shared_brew_casks="$shared_dir/brew-casks.txt"
shared_mas_apps="$shared_dir/mas-apps.txt"
desired_extensions="$shared_dir/vscode-extensions.txt"
keyboard_dir="$shared_dir/macos-keyboard-shortcuts"
keyboard_state_dir="$state_dir/macos-keyboard-shortcuts"
legacy_extensions="$sync_dir/vscode-extensions.txt"
legacy_snapshot_extensions="$sync_dir/vscode-extensions.current.txt"
legacy_last_seen_desired_extensions="$sync_dir/vscode-extensions.last-desired.$safe_name.txt"
last_seen_desired_extensions="$state_dir/vscode-extensions.last-seen.txt"
legacy_keyboard_dir="$sync_dir/macos-keyboard-shortcuts"
tmp_dir="$(mktemp -d)"

installed_brew_packages=()
installed_brew_casks=()
installed_mas_apps=()
installed_vscode_extensions=()
removed_vscode_extensions=()
applied_keyboard_domains=()

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

ensure_file() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
  [[ -f "$file" ]] || : > "$file"
}

sort_unique_file() {
  local file="$1"
  local sorted="$tmp_dir/$(basename "$file").sorted"
  ensure_file "$file"
  awk 'NF' "$file" | LC_ALL=C sort -u > "$sorted"
  mv "$sorted" "$file"
}

print_list() {
  local title="$1"
  local file="$2"
  [[ -s "$file" ]] || return 0
  printf '\n%s\n' "$title"
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    printf '[ ] %s\n' "$item"
  done < "$file"
}

print_array() {
  local title="$1"
  shift
  printf '\n%s\n' "$title"
  if [[ "$#" -eq 0 ]]; then
    printf '  none\n'
    return 0
  fi
  local item
  for item in "$@"; do
    printf '  %s\n' "$item"
  done
}

mas_ids() {
  awk 'NF { print $1 }' "$1" | LC_ALL=C sort -u
}

mkdir -p "$sync_dir" "$inventory_dir" "$state_dir" "$shared_dir" "$keyboard_dir" "$keyboard_state_dir"
cd "$HOME"

"${bare[@]}" pull --ff-only

# Legacy migration from earlier flat sync files.
if [[ ! -f "$desired_extensions" ]]; then
  if [[ -f "$legacy_extensions" ]]; then
    cp "$legacy_extensions" "$desired_extensions"
  elif [[ -f "$legacy_snapshot_extensions" ]]; then
    cp "$legacy_snapshot_extensions" "$desired_extensions"
  fi
fi

if [[ ! -f "$last_seen_desired_extensions" && -f "$legacy_last_seen_desired_extensions" ]]; then
  cp "$legacy_last_seen_desired_extensions" "$last_seen_desired_extensions"
  rm -f "$legacy_last_seen_desired_extensions"
fi

if [[ -d "$legacy_keyboard_dir" ]]; then
  find "$legacy_keyboard_dir" -maxdepth 1 -name '*.plist' -type f -print0 |
    while IFS= read -r -d '' file; do
      target="$keyboard_dir/$(basename "$file")"
      [[ -f "$target" ]] || cp "$file" "$target"
    done
fi

ensure_file "$shared_brew_leaves"
ensure_file "$shared_brew_casks"
ensure_file "$shared_mas_apps"
ensure_file "$desired_extensions"
sort_unique_file "$shared_brew_leaves"
sort_unique_file "$shared_brew_casks"
sort_unique_file "$desired_extensions"

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
brew list --formula | LC_ALL=C sort > "$tmp_dir/brew-formulae.txt"
find /Applications -maxdepth 1 -name "*.app" -print 2>/dev/null \
  | sed 's#^.*/##; s#\.app$##' \
  | grep -v '^\.' \
  | LC_ALL=C sort > "$inventory_dir/applications.txt"

if command -v mas >/dev/null 2>&1; then
  mas list | LC_ALL=C sort > "$inventory_dir/mas-apps.txt"
  rm -f "$inventory_dir/app-store.txt"
else
  rm -f "$inventory_dir/mas-apps.txt" "$inventory_dir/app-store.txt"
fi

missing_brew_packages="$tmp_dir/missing-brew-packages.txt"
missing_brew_casks="$tmp_dir/missing-brew-casks.txt"
undeclared_brew_packages="$tmp_dir/undeclared-brew-packages.txt"
undeclared_brew_casks="$tmp_dir/undeclared-brew-casks.txt"
comm -13 "$tmp_dir/brew-formulae.txt" "$shared_brew_leaves" > "$missing_brew_packages"
comm -13 "$inventory_dir/brew-casks.txt" "$shared_brew_casks" > "$missing_brew_casks"
comm -23 "$inventory_dir/brew-leaves.txt" "$shared_brew_leaves" > "$undeclared_brew_packages"
comm -23 "$inventory_dir/brew-casks.txt" "$shared_brew_casks" > "$undeclared_brew_casks"

while IFS= read -r package; do
  [[ -z "$package" ]] && continue
  brew install "$package"
  installed_brew_packages+=("$package")
done < "$missing_brew_packages"

while IFS= read -r cask; do
  [[ -z "$cask" ]] && continue
  brew install --cask "$cask"
  installed_brew_casks+=("$cask")
done < "$missing_brew_casks"

if command -v mas >/dev/null 2>&1; then
  current_mas_ids="$tmp_dir/current-mas-ids.txt"
  shared_mas_ids="$tmp_dir/shared-mas-ids.txt"
  missing_mas_ids="$tmp_dir/missing-mas-ids.txt"
  undeclared_mas_apps="$tmp_dir/undeclared-mas-apps.txt"
  mas_ids "$inventory_dir/mas-apps.txt" > "$current_mas_ids"
  mas_ids "$shared_mas_apps" > "$shared_mas_ids"
  comm -13 "$current_mas_ids" "$shared_mas_ids" > "$missing_mas_ids"
  awk 'NR == FNR { shared[$1] = 1; next } NF && !shared[$1]' "$shared_mas_apps" "$inventory_dir/mas-apps.txt" > "$undeclared_mas_apps"

  while IFS= read -r app_id; do
    [[ -z "$app_id" ]] && continue
    mas install "$app_id"
    app_name="$(awk -v id="$app_id" '$1 == id { $1=""; sub(/^ /, ""); print; exit }' "$shared_mas_apps")"
    installed_mas_apps+=("$app_id${app_name:+ $app_name}")
  done < "$missing_mas_ids"
else
  undeclared_mas_apps="$tmp_dir/undeclared-mas-apps.txt"
  : > "$undeclared_mas_apps"
fi

if command -v code >/dev/null 2>&1; then
  current_extensions="$tmp_dir/vscode-current.txt"
  code --list-extensions | LC_ALL=C sort > "$current_extensions"

  if [[ ! -s "$desired_extensions" ]]; then
    cp "$current_extensions" "$desired_extensions"
    echo "Initialized shared VS Code extension list from this Mac."
  fi

  local_changed=false
  if [[ -f "$last_seen_desired_extensions" ]] && ! cmp -s "$current_extensions" "$last_seen_desired_extensions"; then
    local_changed=true
  fi

  if cmp -s "$current_extensions" "$desired_extensions"; then
    :
  elif [[ "$local_changed" == true ]]; then
    cp "$current_extensions" "$desired_extensions"
    echo "Adopted this Mac's VS Code extensions as the shared list."
  else
    missing_extensions="$tmp_dir/vscode-missing.txt"
    extra_extensions="$tmp_dir/vscode-extra.txt"
    comm -13 "$current_extensions" "$desired_extensions" > "$missing_extensions"
    comm -23 "$current_extensions" "$desired_extensions" > "$extra_extensions"

    while IFS= read -r extension; do
      [[ -z "$extension" ]] && continue
      code --install-extension "$extension"
      installed_vscode_extensions+=("$extension")
    done < "$missing_extensions"

    while IFS= read -r extension; do
      [[ -z "$extension" ]] && continue
      code --uninstall-extension "$extension"
      removed_vscode_extensions+=("$extension")
    done < "$extra_extensions"

    code --list-extensions | LC_ALL=C sort > "$current_extensions"
  fi

  cp "$desired_extensions" "$last_seen_desired_extensions"
else
  echo "VS Code CLI not found; skipped extension sync."
fi

keyboard_domains=()
for file in "$keyboard_dir"/*.plist "$legacy_keyboard_dir"/*.plist; do
  [[ -e "$file" ]] || continue
  domain="$(basename "$file" .plist)"
  keyboard_domains+=("$domain")
done
if [[ "${#keyboard_domains[@]}" -eq 0 ]]; then
  keyboard_domains=(NSGlobalDomain com.apple.Safari net.imput.helium)
fi

printf '%s\n' "${keyboard_domains[@]}" | LC_ALL=C sort -u > "$tmp_dir/keyboard-domains.txt"
while IFS= read -r domain; do
  [[ -z "$domain" ]] && continue
  current_shortcuts="$tmp_dir/$domain.current.plist"
  shared_shortcuts="$keyboard_dir/$domain.plist"
  last_seen_shortcuts="$keyboard_state_dir/$domain.plist"

  if ! defaults read "$domain" NSUserKeyEquivalents > "$current_shortcuts" 2>/dev/null; then
    continue
  fi

  if [[ ! -f "$shared_shortcuts" ]]; then
    cp "$current_shortcuts" "$shared_shortcuts"
  elif [[ -f "$last_seen_shortcuts" ]] && ! cmp -s "$current_shortcuts" "$last_seen_shortcuts"; then
    cp "$current_shortcuts" "$shared_shortcuts"
  elif ! cmp -s "$current_shortcuts" "$shared_shortcuts"; then
    defaults write "$domain" NSUserKeyEquivalents "$(cat "$shared_shortcuts")"
    applied_keyboard_domains+=("$domain")
  fi

  cp "$shared_shortcuts" "$last_seen_shortcuts"
done < "$tmp_dir/keyboard-domains.txt"

if [[ "${#applied_keyboard_domains[@]}" -gt 0 ]]; then
  killall cfprefsd 2>/dev/null || true
fi

if [[ "${#installed_brew_packages[@]}" -gt 0 || "${#installed_brew_casks[@]}" -gt 0 ]]; then
  brew leaves | LC_ALL=C sort > "$inventory_dir/brew-leaves.txt"
  brew list --cask | LC_ALL=C sort > "$inventory_dir/brew-casks.txt"
fi

if [[ "${#installed_mas_apps[@]}" -gt 0 ]] && command -v mas >/dev/null 2>&1; then
  mas list | LC_ALL=C sort > "$inventory_dir/mas-apps.txt"
fi

print_list "Brew packages installed here but not shared:" "$undeclared_brew_packages"
print_list "Casks installed here but not shared:" "$undeclared_brew_casks"
print_list "App Store apps installed here but not shared:" "$undeclared_mas_apps"

printf '\nSync report for %s\n' "$computer_name"
if [[ "${#installed_brew_packages[@]}" -gt 0 ]]; then
  print_array "Installed Brew packages:" "${installed_brew_packages[@]}"
else
  print_array "Installed Brew packages:"
fi
if [[ "${#installed_brew_casks[@]}" -gt 0 ]]; then
  print_array "Installed Brew casks:" "${installed_brew_casks[@]}"
else
  print_array "Installed Brew casks:"
fi
if [[ "${#installed_mas_apps[@]}" -gt 0 ]]; then
  print_array "Installed App Store apps:" "${installed_mas_apps[@]}"
else
  print_array "Installed App Store apps:"
fi
if [[ "${#installed_vscode_extensions[@]}" -gt 0 ]]; then
  print_array "Installed VS Code extensions:" "${installed_vscode_extensions[@]}"
else
  print_array "Installed VS Code extensions:"
fi
if [[ "${#removed_vscode_extensions[@]}" -gt 0 ]]; then
  print_array "Removed VS Code extensions:" "${removed_vscode_extensions[@]}"
else
  print_array "Removed VS Code extensions:"
fi
if [[ "${#applied_keyboard_domains[@]}" -gt 0 ]]; then
  print_array "Applied keyboard shortcut domains:" "${applied_keyboard_domains[@]}"
else
  print_array "Applied keyboard shortcut domains:"
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
