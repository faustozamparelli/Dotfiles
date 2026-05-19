#!/usr/bin/env bash
set -euo pipefail

if ! command -v code >/dev/null 2>&1; then
  echo "VS Code CLI 'code' was not found in PATH."
  echo "In VS Code, run: Shell Command: Install 'code' command in PATH"
  exit 1
fi

files=()

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  root="$(git rev-parse --show-toplevel)"
  cd "$root"

  while IFS= read -r file; do
    [[ -n "$file" ]] && files+=("$file")
  done < <({ git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } | awk '!seen[$0]++')
else
  while IFS= read -r file; do
    [[ -n "$file" ]] && files+=("$file")
  done < <(find . -type f \
    -not -path './.git/*' \
    -not -path './node_modules/*' \
    -not -path './.DS_Store' \
    -mmin -120 \
    -print | sed 's#^./##')
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No changed files found."
  exit 0
fi

code -r "${files[@]}"
printf 'Opened in VS Code:\n'
printf ' - %s\n' "${files[@]}"
