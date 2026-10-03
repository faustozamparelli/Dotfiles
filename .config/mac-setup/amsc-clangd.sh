#!/usr/bin/env bash
set -euo pipefail

shared="$HOME/shared-folder"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.orbstack/bin:$PATH"

# Editors may supply their own indexing/worker policy. Keep Neovim's defaults
# only when no arguments were supplied, and forward VS Code's lean arguments.
if [[ $# -eq 0 ]]; then
  set -- --background-index --clang-tidy
fi

# Neovim starts clangd in the project root. Files under the bind mount must be
# analyzed on Linux so module headers and the container compiler are visible.
if [[ "$PWD" == "$shared" || "$PWD" == "$shared/"* ]]; then
  if ! command -v docker >/dev/null 2>&1 ||
     [[ "$(docker inspect --format '{{.State.Running}}' amsc 2>/dev/null || true)" != true ]] ||
     ! docker exec amsc test -x /usr/bin/clangd >/dev/null 2>&1; then
    echo 'AMSC clangd needs the running amsc container. Start it with: docker start amsc' >&2
    exit 1
  fi
  container_cwd="/shared-folder${PWD#"$shared"}"
  exec docker exec -i -w "$container_cwd" amsc /bin/bash -c '
    source /u/sw/etc/profile.d/mk.sh
    module load gcc-glibc/11.2.0 >&2 || exit
    shared="$1"
    shift
    exec /usr/bin/clangd \
      --path-mappings="$shared=/shared-folder" \
      --query-driver=/u/sw/toolchains/gcc-glibc/11.2.0/prefix/bin/gcc,/u/sw/toolchains/gcc-glibc/11.2.0/prefix/bin/g++ \
      "$@"
  ' amsc-clangd "$shared" "$@"
fi

exec /usr/bin/clangd "$@"
