#!/usr/bin/env bash
set -euo pipefail

script_under_test="$(cd "$(dirname "$0")/.." && pwd)/maintain.sh"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

home="$tmp_dir/home"
bin="$tmp_dir/bin"
mkdir -p "$home/.config/git/dotfiles" "$home/.config/sync/shared" "$home/.config/sync/state/fausto-s-macbook-air" "$bin"

cat > "$bin/git" <<'EOF'
#!/usr/bin/env bash
log="$HOME/git.log"
case "$*" in
  *" pull --ff-only")
    echo "git pull" >> "$log"
    exit 0
    ;;
  *" add "*)
    echo "git add ${*: -1}" >> "$log"
    exit 0
    ;;
  *" status --short")
    echo "git status" >> "$log"
    exit 0
    ;;
esac
echo "unexpected git args: $*" >> "$log"
exit 0
EOF

cat > "$bin/scutil" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "--get ComputerName" ]]; then
  printf '%s\n' "Fausto's MacBook Air"
  exit 0
fi
exit 1
EOF

cat > "$bin/sw_vers" <<'EOF'
#!/usr/bin/env bash
printf 'ProductName:\tmacOS\nProductVersion:\t26.5.1\nBuildVersion:\t25F80\n'
EOF

cat > "$bin/brew" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --prefix)
    printf '/opt/homebrew\n'
    ;;
  --version)
    printf 'Homebrew 5.1.15\n'
    ;;
  leaves)
    printf 'local-pkg\n'
    ;;
  list)
    if [[ "${2:-}" == "--cask" ]]; then
      printf 'local-cask\n'
    elif [[ "${2:-}" == "--formula" ]]; then
      printf 'local-pkg\n'
    fi
    ;;
  install)
    shift
    printf '%s\n' "$*" >> "$HOME/brew-installs.log"
    ;;
  *)
    echo "unexpected brew args: $*" >&2
    exit 1
    ;;
esac
EOF

cat > "$bin/code" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --list-extensions)
    if [[ -f "$HOME/code-extensions.current" ]]; then
      cat "$HOME/code-extensions.current"
    fi
    ;;
  --install-extension)
    printf 'install %s\n' "$2" >> "$HOME/code-actions.log"
    ;;
  --uninstall-extension)
    printf 'uninstall %s\n' "$2" >> "$HOME/code-actions.log"
    ;;
  *)
    echo "unexpected code args: $*" >&2
    exit 1
    ;;
esac
EOF

cat > "$bin/mas" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  list)
    printf '111111111 Local App\n'
    ;;
  install)
    printf '%s\n' "$2" >> "$HOME/mas-installs.log"
    ;;
  *)
    echo "unexpected mas args: $*" >&2
    exit 1
    ;;
esac
EOF

cat > "$bin/defaults" <<'EOF'
#!/usr/bin/env bash
case "$1 $3" in
  "read NSUserKeyEquivalents")
    printf '{"Example" = "@e";}\n'
    ;;
  "write NSUserKeyEquivalents")
    printf 'defaults write %s\n' "$2" >> "$HOME/defaults-actions.log"
    ;;
  *)
    exit 1
    ;;
esac
EOF

cat > "$bin/killall" <<'EOF'
#!/usr/bin/env bash
printf 'killall %s\n' "$1" >> "$HOME/killall.log"
EOF

chmod +x "$bin/"*

cat > "$home/.config/sync/shared/brew-leaves.txt" <<'EOF'
shared-pkg
EOF

cat > "$home/.config/sync/shared/brew-casks.txt" <<'EOF'
shared-cask
EOF

cat > "$home/.config/sync/shared/mas-apps.txt" <<'EOF'
222222222 Shared App
EOF

cat > "$home/.config/sync/shared/vscode-extensions.txt" <<'EOF'
shared.extension
EOF

cat > "$home/.config/sync/state/fausto-s-macbook-air/vscode-extensions.last-seen.txt" <<'EOF'
local.extension
EOF

cat > "$home/code-extensions.current" <<'EOF'
local.extension
EOF

output="$(
  HOME="$home" \
  PATH="$bin:/usr/bin:/bin" \
  "$script_under_test"
)"

grep -q '^shared-pkg$' "$home/brew-installs.log"
grep -q '^--cask shared-cask$' "$home/brew-installs.log"
grep -q '^222222222$' "$home/mas-installs.log"
grep -q '^install shared.extension$' "$home/code-actions.log"
grep -q '^uninstall local.extension$' "$home/code-actions.log"
grep -q 'Brew packages installed here but not shared:' <<<"$output"
grep -q '\[ \] local-pkg' <<<"$output"
grep -q 'Casks installed here but not shared:' <<<"$output"
grep -q '\[ \] local-cask' <<<"$output"
grep -q 'App Store apps installed here but not shared:' <<<"$output"
grep -q '\[ \] 111111111 Local App' <<<"$output"
grep -q 'Installed Brew packages:' <<<"$output"
grep -q 'Installed Brew casks:' <<<"$output"
grep -q 'Installed App Store apps:' <<<"$output"
