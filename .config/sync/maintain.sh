#!/usr/bin/env bash
set -euo pipefail

sync_dir="${SYNC_DIR:-$HOME/.config/sync}"
bare=(git --git-dir="$HOME/.config/git/dotfiles" --work-tree="$HOME")
computer_name="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
safe_name="$(printf '%s' "$computer_name" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-')"
safe_name="${safe_name%-}"
inventory_dir="$sync_dir/inventory/$safe_name"
state_dir="$sync_dir/state/$safe_name"
review_dir="$sync_dir"
review_file="$sync_dir/software-$safe_name.txt"
legacy_review_dir="$sync_dir/review"
review_last_seen="$state_dir/software-review.last-seen.txt"
shared_dir="$sync_dir/shared"
shared_brew_leaves="$shared_dir/brew-leaves.txt"
shared_brew_casks="$shared_dir/brew-casks.txt"
shared_mas_apps="$shared_dir/mas-apps.txt"
keyboard_dir="$shared_dir/macos-keyboard-shortcuts"
keyboard_state_dir="$state_dir/macos-keyboard-shortcuts"
legacy_keyboard_dir="$sync_dir/macos-keyboard-shortcuts"
tmp_dir="$(mktemp -d)"

installed_brew_packages=()
installed_brew_casks=()
installed_mas_apps=()
applied_keyboard_domains=()
newly_local_software=()
declassified_software=()

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

plist_dict_is_empty() {
  [[ "$(tr -d '[:space:]' < "$1")" == "{}" ]]
}

validate_review_file() {
  local file="$1"
  awk -F '\t' '
    BEGIN { valid = 1 }
    /^#/ || NF == 0 { next }
    {
      if (NF != 3 && NF != 4) {
        printf "Invalid review row in %s: expected tab-separated type, item, shared, and local columns: %s\n", FILENAME, $0 > "/dev/stderr"
        valid = 0
        next
      }
      if ($1 != "brew" && $1 != "cask" && $1 != "mas") {
        printf "Invalid software type in %s: %s\n", FILENAME, $1 > "/dev/stderr"
        valid = 0
      }
      shared = ($3 == "[.]" || $3 == ".")
      local = ($4 == "[.]" || $4 == ".")
      shared_empty = ($3 == "[]" || $3 == "[ ]" || $3 == "")
      local_empty = (NF == 3 || $4 == "[]" || $4 == "[ ]" || $4 == "")
      if ($2 == "" || !((shared && local_empty) || (shared_empty && local))) {
        printf "Select exactly one bucket in %s: %s\n", FILENAME, $0 > "/dev/stderr"
        valid = 0
      }
      key = $1 SUBSEP $2
      if (seen[key]++) {
        printf "Duplicate software row in %s: %s %s\n", FILENAME, $1, $2 > "/dev/stderr"
        valid = 0
      }
    }
    END { exit !valid }
  ' "$file"
}

normalize_review_file() {
  local file="$1"
  local body="$tmp_dir/$(basename "$file").review-body"
  awk -F '\t' 'BEGIN { OFS = "\t" } !/^#/ && NF {
    if ($3 == "." || $3 == "[.]") print $1, $2, "[.]", "[]"
    else print $1, $2, "[]", "[.]"
  }' "$file" |
    LC_ALL=C sort -t $'\t' -k1,1 -k2,2 > "$body"
  {
    printf '# Move [.] between shared and local, then run sync-maintain.\n'
    printf '# type\titem\tshared\tlocal\n'
    cat "$body"
  } > "$file"
}

set_item_local_in_all_reviews() {
  local type="$1"
  local item="$2"
  local file updated
  for file in "$review_dir"/software-*.txt; do
    [[ -e "$file" ]] || continue
    updated="$tmp_dir/$(basename "$file").declassified"
    awk -F '\t' -v OFS='\t' -v type="$type" -v item="$item" '
      /^#/ || NF == 0 { print; next }
      $1 == type && $2 == item { $3 = "[]"; $4 = "[.]" }
      { print }
    ' "$file" > "$updated"
    mv "$updated" "$file"
    normalize_review_file "$file"
  done
}

set_item_shared_in_all_reviews() {
  local type="$1"
  local item="$2"
  local file updated
  for file in "$review_dir"/software-*.txt; do
    [[ -e "$file" ]] || continue
    updated="$tmp_dir/$(basename "$file").shared"
    awk -F '\t' -v OFS='\t' -v type="$type" -v item="$item" '
      /^#/ || NF == 0 { print; next }
      $1 == type && $2 == item { $3 = "[.]"; $4 = "[]" }
      { print }
    ' "$file" > "$updated"
    mv "$updated" "$file"
    normalize_review_file "$file"
  done
}

inventory_records() {
  awk 'NF { print "brew\t" $0 }' "$inventory_dir/brew-leaves.txt"
  awk 'NF { print "cask\t" $0 }' "$inventory_dir/brew-casks.txt"
  if [[ -f "$inventory_dir/mas-apps.txt" ]]; then
    awk 'NF { print "mas\t" $0 }' "$inventory_dir/mas-apps.txt"
  fi
}

is_legacy_shared() {
  local type="$1"
  local item="$2"
  case "$type" in
    brew) grep -Fxq "$item" "$shared_brew_leaves" ;;
    cask) grep -Fxq "$item" "$shared_brew_casks" ;;
    mas) grep -Eq "^${item%% *}( |$)" "$shared_mas_apps" ;;
  esac
}

global_shared_keys() {
  awk -F '\t' '!/^#/ && NF >= 3 && ($3 == "." || $3 == "[.]") { print $1 "\t" $2 }' "$review_dir"/software-*.txt 2>/dev/null |
    LC_ALL=C sort -u
}

reconcile_review_file() {
  local installed="$tmp_dir/installed-software.txt"
  local old="$tmp_dir/current-review-old.txt"
  local shared_keys="$tmp_dir/global-shared-keys.txt"
  local next="$tmp_dir/current-review-next.txt"
  local type item bucket key

  inventory_records | LC_ALL=C sort -u > "$installed"

  if [[ ! -f "$review_file" ]]; then
    : > "$next"
    while IFS=$'\t' read -r type item; do
      [[ -n "$type" ]] || continue
      if is_legacy_shared "$type" "$item"; then
        printf '%s\t%s\t[.]\t[]\n' "$type" "$item" >> "$next"
      else
        printf '%s\t%s\t[]\t[.]\n' "$type" "$item" >> "$next"
        newly_local_software+=("$type $item")
      fi
    done < "$installed"
    mv "$next" "$review_file"
    normalize_review_file "$review_file"
    return
  fi

  validate_review_file "$review_file"

  if [[ -f "$review_last_seen" ]]; then
    awk -F '\t' '
      NR == FNR {
        if (!/^#/ && NF >= 3 && ($3 == "." || $3 == "[.]")) previous[$1 SUBSEP $2] = 1
        next
      }
      !/^#/ && NF == 4 && ($4 == "." || $4 == "[.]") && previous[$1 SUBSEP $2] { print $1 "\t" $2 }
    ' "$review_last_seen" "$review_file" > "$tmp_dir/explicit-declassifications.txt"
    while IFS=$'\t' read -r type item; do
      [[ -n "$type" ]] || continue
      set_item_local_in_all_reviews "$type" "$item"
      declassified_software+=("$type $item")
    done < "$tmp_dir/explicit-declassifications.txt"
  fi

  awk -F '\t' 'BEGIN { OFS = "\t" } !/^#/ && NF >= 3 { print $1, $2, $3, (NF == 4 ? $4 : "") }' "$review_file" > "$old"

  while IFS=$'\t' read -r type item bucket; do
    [[ -n "$type" ]] || continue
    if ! grep -Fxq "$type"$'\t'"$item" "$installed"; then
      if [[ "$bucket" == "shared" ]]; then
        set_item_local_in_all_reviews "$type" "$item"
        declassified_software+=("$type $item")
      fi
    fi
  done < <(awk -F '\t' '!/^#/ && NF >= 3 { print $1 "\t" $2 "\t" (($3 == "." || $3 == "[.]") ? "shared" : "local") }' "$review_file")

  global_shared_keys > "$shared_keys"
  : > "$next"
  while IFS=$'\t' read -r type item; do
    [[ -n "$type" ]] || continue
    key="$type"$'\t'"$item"
    if grep -Fxq "$key" "$shared_keys"; then
      printf '%s\t%s\t[.]\t[]\n' "$type" "$item" >> "$next"
    elif awk -F '\t' -v type="$type" -v item="$item" '$1 == type && $2 == item { found = 1; exit } END { exit !found }' "$old"; then
      awk -F '\t' -v type="$type" -v item="$item" '$1 == type && $2 == item { print; exit }' "$old" >> "$next"
    else
      printf '%s\t%s\t[]\t[.]\n' "$type" "$item" >> "$next"
      newly_local_software+=("$type $item")
    fi
  done < "$installed"
  mv "$next" "$review_file"
  normalize_review_file "$review_file"
}

generate_shared_files() {
  local file type item
  for file in "$review_dir"/software-*.txt; do
    [[ -e "$file" ]] || continue
    validate_review_file "$file"
  done
  global_shared_keys > "$tmp_dir/shared-keys-to-propagate.txt"
  while IFS=$'\t' read -r type item; do
    [[ -n "$type" ]] || continue
    set_item_shared_in_all_reviews "$type" "$item"
  done < "$tmp_dir/shared-keys-to-propagate.txt"
  awk -F '\t' '!/^#/ && NF >= 3 && $1 == "brew" && ($3 == "." || $3 == "[.]") { print $2 }' "$review_dir"/software-*.txt 2>/dev/null |
    LC_ALL=C sort -u > "$shared_brew_leaves"
  awk -F '\t' '!/^#/ && NF >= 3 && $1 == "cask" && ($3 == "." || $3 == "[.]") { print $2 }' "$review_dir"/software-*.txt 2>/dev/null |
    LC_ALL=C sort -u > "$shared_brew_casks"
  awk -F '\t' '!/^#/ && NF >= 3 && $1 == "mas" && ($3 == "." || $3 == "[.]") { print $2 }' "$review_dir"/software-*.txt 2>/dev/null |
    LC_ALL=C sort -u > "$shared_mas_apps"
}

mkdir -p "$sync_dir" "$inventory_dir" "$state_dir" "$review_dir" "$shared_dir" "$keyboard_dir" "$keyboard_state_dir"
cd "$HOME"

"${bare[@]}" pull --ff-only

if [[ -d "$legacy_review_dir" ]]; then
  for file in "$legacy_review_dir"/*.txt; do
    [[ -e "$file" ]] || continue
    target="$sync_dir/software-$(basename "$file")"
    [[ -f "$target" ]] || mv "$file" "$target"
  done
  rmdir "$legacy_review_dir" 2>/dev/null || true
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

reconcile_review_file
generate_shared_files
cp "$review_file" "$review_last_seen"

missing_brew_packages="$tmp_dir/missing-brew-packages.txt"
missing_brew_casks="$tmp_dir/missing-brew-casks.txt"
comm -13 "$tmp_dir/brew-formulae.txt" "$shared_brew_leaves" > "$missing_brew_packages"
comm -13 "$inventory_dir/brew-casks.txt" "$shared_brew_casks" > "$missing_brew_casks"

while IFS= read -r package; do
  [[ -z "$package" ]] && continue
  brew install "$package"
  installed_brew_packages+=("$package")
done < "$missing_brew_packages"

if command -v tmux >/dev/null 2>&1 && [[ ! -x "$HOME/.local/share/tmux/plugins/tmux-resurrect/scripts/save.sh" ]]; then
  "$HOME/.config/tmux/install-plugins"
fi

while IFS= read -r cask; do
  [[ -z "$cask" ]] && continue
  brew install --cask "$cask"
  installed_brew_casks+=("$cask")
done < "$missing_brew_casks"

if command -v mas >/dev/null 2>&1; then
  current_mas_ids="$tmp_dir/current-mas-ids.txt"
  shared_mas_ids="$tmp_dir/shared-mas-ids.txt"
  missing_mas_ids="$tmp_dir/missing-mas-ids.txt"
  mas_ids "$inventory_dir/mas-apps.txt" > "$current_mas_ids"
  mas_ids "$shared_mas_apps" > "$shared_mas_ids"
  comm -13 "$current_mas_ids" "$shared_mas_ids" > "$missing_mas_ids"

  while IFS= read -r app_id; do
    [[ -z "$app_id" ]] && continue
    mas install "$app_id"
    app_name="$(awk -v id="$app_id" '$1 == id { $1=""; sub(/^ /, ""); print; exit }' "$shared_mas_apps")"
    installed_mas_apps+=("$app_id${app_name:+ $app_name}")
  done < "$missing_mas_ids"
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
  elif plist_dict_is_empty "$current_shortcuts" && ! plist_dict_is_empty "$shared_shortcuts"; then
    defaults write "$domain" NSUserKeyEquivalents "$(cat "$shared_shortcuts")"
    applied_keyboard_domains+=("$domain")
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

brew leaves | LC_ALL=C sort > "$inventory_dir/brew-leaves.txt"
brew list --cask | LC_ALL=C sort > "$inventory_dir/brew-casks.txt"
brew list --formula | LC_ALL=C sort > "$tmp_dir/brew-formulae.txt"
if command -v mas >/dev/null 2>&1; then
  mas list | LC_ALL=C sort > "$inventory_dir/mas-apps.txt"
fi

reconcile_review_file
generate_shared_files
cp "$review_file" "$review_last_seen"

printf '\nSync report for %s\n' "$computer_name"
if [[ "${#newly_local_software[@]}" -gt 0 ]]; then
  print_array "Software newly classified as local:" "${newly_local_software[@]}"
else
  print_array "Software newly classified as local:"
fi
if [[ "${#declassified_software[@]}" -gt 0 ]]; then
  print_array "Software declassified from shared:" "${declassified_software[@]}"
else
  print_array "Software declassified from shared:"
fi
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
if [[ "${#applied_keyboard_domains[@]}" -gt 0 ]]; then
  print_array "Applied keyboard shortcut domains:" "${applied_keyboard_domains[@]}"
else
  print_array "Applied keyboard shortcut domains:"
fi

for marta_file in \
  "Library/Application Support/org.yanex.marta/conf.marco" \
  "Library/Application Support/org.yanex.marta/favorites.marco"; do
  [[ -f "$HOME/$marta_file" ]] && "${bare[@]}" add "$marta_file"
done

"${bare[@]}" add \
  .config/sync \
  .config/keymaps \
  .config/nvim \
  .config/tmux \
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
