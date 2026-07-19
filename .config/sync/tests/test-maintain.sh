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
mkdir -p \
  "$home/.config/git/dotfiles" \
  "$home/.config/sync/shared" \
  "$home/.config/sync/state/fausto-s-macbook-air" \
  "$home/.codex/bin" \
  "$home/.codex/modes" \
  "$home/.codex/skills/personal-skill" \
  "$home/.codex/skills/.system/system-skill" \
  "$home/.codex/themes" \
  "$home/cellar" \
  "$bin"

touch \
  "$home/.codex/bin/codex-stealth" \
  "$home/.codex/modes/stealth.md" \
  "$home/.codex/skills/personal-skill/SKILL.md" \
  "$home/.codex/skills/.system/system-skill/SKILL.md" \
  "$home/.codex/stealth.config.toml" \
  "$home/.codex/themes/stealth.tmTheme"

for formula in explicit-local local-pkg promoted-current remote-present shared-installed; do
  mkdir -p "$home/cellar/$formula/1.0"
  printf '%s\n' '{"installed_on_request":true,"source":{"tap":"homebrew/core"}}' \
    > "$home/cellar/$formula/1.0/INSTALL_RECEIPT.json"
done

cat > "$bin/git" <<'EOF'
#!/usr/bin/env bash
log="$HOME/git.log"
case "$*" in
  *" pull --ff-only")
    echo "git pull" >> "$log"
    exit 0
    ;;
  *" add "*)
    args=("$@")
    for ((i = 0; i < ${#args[@]}; i++)); do
      if [[ "${args[$i]}" == "add" ]]; then
        for ((j = i + 1; j < ${#args[@]}; j++)); do
          [[ "${args[$j]}" == -* ]] && continue
          echo "git add ${args[$j]}" >> "$log"
        done
        break
      fi
    done
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
  --cellar)
    printf '%s/cellar\n' "$HOME"
    ;;
  --prefix)
    printf '/opt/homebrew\n'
    ;;
  --version)
    printf 'Homebrew 5.1.15\n'
    ;;
  leaves)
    printf 'explicit-local\nlocal-pkg\npromoted-current\nremote-present\nshared-installed\n'
    ;;
  list)
    if [[ "${2:-}" == "--cask" ]]; then
      printf 'local-cask\nmarta\nshared-cask\n'
    elif [[ "${2:-}" == "--formula" ]]; then
      printf 'explicit-local\nlocal-pkg\npromoted-current\nremote-present\nshared-installed\n'
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

cat > "$bin/mas" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  list)
    printf '111111111 Local App\n222222222 Shared App\n'
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
    if [[ -f "$HOME/defaults-empty" ]]; then
      printf '{}\n'
    else
      printf '{"Example" = "@e";}\n'
    fi
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
legacy-absent
EOF

cat > "$home/.config/sync/shared/brew-casks.txt" <<'EOF'
legacy-cask
EOF

cat > "$home/.config/sync/shared/mas-apps.txt" <<'EOF'
333333333 Legacy App
EOF

printf '# type\titem\tshared\tlocal\nbrew\texplicit-local\t\t.\nbrew\tpromoted-current\t.\t\nbrew\tremote-present\t\t.\nbrew\tshared-installed\t.\t\nbrew\tremoved-shared\t.\t\nbrew\tremoved-local\t\t.\ncask\tshared-cask\t.\t\nmas\t222222222 Shared App\t.\t\n' \
  > "$home/.config/sync/software-fausto-s-macbook-air.txt"

printf '# type\titem\tshared\tlocal\nbrew\texplicit-local\t.\t\nbrew\tpromoted-current\t\t.\nbrew\tremote-present\t.\t\nbrew\tremoved-shared\t.\t\nbrew\tremote-shared\t.\t\n' \
  > "$home/.config/sync/software-fausto-s-macbook-pro.txt"

printf '# type\titem\tshared\tlocal\nbrew\texplicit-local\t.\t\n' \
  > "$home/.config/sync/state/fausto-s-macbook-air/software-review.last-seen.txt"

output="$(
  HOME="$home" \
  PATH="$bin:/usr/bin:/bin" \
  "$script_under_test"
)"

grep -q '^remote-shared$' "$home/brew-installs.log"
! grep -q 'legacy-absent' "$home/brew-installs.log"
! grep -q 'legacy-cask' "$home/brew-installs.log"
[[ ! -f "$home/mas-installs.log" ]]
grep -q $'^brew\tlocal-pkg\t\\[\\]\t\\[\\.\\]$' "$home/.config/sync/software-fausto-s-macbook-air.txt"
grep -q $'^cask\tmarta\t\\[\\]\t\\[\\.\\]$' "$home/.config/sync/software-fausto-s-macbook-air.txt"

: > "$home/defaults-empty"
: > "$home/defaults-actions.log"
HOME="$home" PATH="$bin:/usr/bin:/bin" "$script_under_test" >/dev/null
grep -q '^defaults write com.apple.Safari$' "$home/defaults-actions.log"
grep -q 'Example' "$home/.config/sync/shared/macos-keyboard-shortcuts/com.apple.Safari.plist"
cmp -s \
  "$home/.config/sync/shared/macos-keyboard-shortcuts/com.apple.Safari.plist" \
  "$home/.config/sync/state/fausto-s-macbook-air/macos-keyboard-shortcuts/com.apple.Safari.plist"

mkdir -p "$home/.config/sync/review"
mv \
  "$home/.config/sync/software-fausto-s-macbook-pro.txt" \
  "$home/.config/sync/review/fausto-s-macbook-pro.txt"
HOME="$home" PATH="$bin:/usr/bin:/bin" "$script_under_test" >/dev/null
test -f "$home/.config/sync/software-fausto-s-macbook-pro.txt"
test ! -d "$home/.config/sync/review"
grep -q $'^mas\t111111111 Local App\t\\[\\]\t\\[\\.\\]$' "$home/.config/sync/software-fausto-s-macbook-air.txt"
! grep -q 'removed-local' "$home/.config/sync/software-fausto-s-macbook-air.txt"
! grep -q 'removed-shared' "$home/.config/sync/software-fausto-s-macbook-air.txt"
grep -q $'^brew\tremoved-shared\t\\[\\]\t\\[\\.\\]$' "$home/.config/sync/software-fausto-s-macbook-pro.txt"
grep -q $'^brew\texplicit-local\t\\[\\]\t\\[\\.\\]$' "$home/.config/sync/software-fausto-s-macbook-pro.txt"
grep -q $'^brew\tremote-present\t\\[\\.\\]\t\\[\\]$' "$home/.config/sync/software-fausto-s-macbook-air.txt"
grep -q $'^brew\tpromoted-current\t\\[\\.\\]\t\\[\\]$' "$home/.config/sync/software-fausto-s-macbook-pro.txt"
! grep -q 'removed-shared' "$home/.config/sync/shared/brew-leaves.txt"
! grep -q 'explicit-local' "$home/.config/sync/shared/brew-leaves.txt"
grep -q '^remote-shared$' "$home/.config/sync/shared/brew-leaves.txt"
grep -q '^shared-installed$' "$home/.config/sync/shared/brew-leaves.txt"
grep -q '^shared-cask$' "$home/.config/sync/shared/brew-casks.txt"
grep -q '^222222222 Shared App$' "$home/.config/sync/shared/mas-apps.txt"
grep -q 'Software newly classified as local:' <<<"$output"
grep -q 'Installed Brew packages:' <<<"$output"
grep -q 'Installed Brew casks:' <<<"$output"
grep -q 'Installed App Store apps:' <<<"$output"
grep -q 'Shared applications missing from /Applications:' <<<"$output"
grep -q '^git add .config/keymaps$' "$home/git.log"
grep -q '^git add .config/nvim$' "$home/git.log"
grep -q '^git add .config/tmux$' "$home/git.log"
grep -q '^git add .codex/skills/personal-skill$' "$home/git.log"
! grep -q '\.codex/skills/\.system' "$home/git.log"
grep -q '^git add .codex/bin/codex-stealth$' "$home/git.log"
grep -q '^git add .codex/modes/stealth.md$' "$home/git.log"
grep -q '^git add .codex/stealth.config.toml$' "$home/git.log"
grep -q '^git add .codex/themes/stealth.tmTheme$' "$home/git.log"

cp "$home/.config/sync/software-fausto-s-macbook-air.txt" "$home/review-valid.txt"
printf 'brew\tinvalid-selection\t[.]\t[.]\n' >> "$home/.config/sync/software-fausto-s-macbook-air.txt"
if HOME="$home" PATH="$bin:/usr/bin:/bin" "$script_under_test" >"$home/invalid.out" 2>"$home/invalid.err"; then
  echo "invalid review unexpectedly succeeded" >&2
  exit 1
fi
grep -q 'Select exactly one bucket' "$home/invalid.err"
mv "$home/review-valid.txt" "$home/.config/sync/software-fausto-s-macbook-air.txt"

rm -f \
  "$home/.config/sync/software-fausto-s-macbook-air.txt" \
  "$home/.config/sync/state/fausto-s-macbook-air/software-review.last-seen.txt"
printf 'legacy-absent\nshared-installed\n' > "$home/.config/sync/shared/brew-leaves.txt"
HOME="$home" PATH="$bin:/usr/bin:/bin" "$script_under_test" >/dev/null
! grep -q 'legacy-absent' "$home/.config/sync/software-fausto-s-macbook-air.txt"
! grep -q 'legacy-absent' "$home/brew-installs.log"
grep -q $'^cask\tmarta\t\\[\\]\t\\[\\.\\]$' "$home/.config/sync/software-fausto-s-macbook-air.txt"
