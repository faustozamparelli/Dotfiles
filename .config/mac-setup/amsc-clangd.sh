#!/usr/bin/env bash
set -euo pipefail

shared="$HOME/shared-folder"

# Neovim starts clangd in the project root. Files under the bind mount must be
# analyzed on Linux so module headers and the container compiler are visible.
if [[ "$PWD" == "$shared" || "$PWD" == "$shared/"* ]] &&
   command -v docker >/dev/null 2>&1 &&
   [[ "$(docker inspect --format '{{.State.Running}}' amsc 2>/dev/null || true)" == true ]] &&
   docker exec amsc test -x /usr/bin/clangd >/dev/null 2>&1; then
  exec docker exec -i amsc /bin/bash -c '
    source /u/sw/etc/profile.d/mk.sh
    module load gcc-glibc/11.2.0 lis/2.0.30 >&2
    exec /usr/bin/clangd \
      --path-mappings="$1=/shared-folder" \
      --query-driver=/u/sw/toolchains/gcc-glibc/11.2.0/prefix/bin/gcc,/u/sw/toolchains/gcc-glibc/11.2.0/prefix/bin/g++ \
      --background-index --clang-tidy
  ' amsc-clangd "$shared"
fi

exec /usr/bin/clangd --background-index --clang-tidy
