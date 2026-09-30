#!/usr/bin/env bash
set -euo pipefail

# Emit clangd configuration for the libraries installed in the AMSC image.
# This runs on the Mac while the container is running; paths stay on Linux.
toolchain=/u/sw/toolchains/gcc-glibc/11.2.0
headers="$(docker exec amsc find "$toolchain/pkgs" -mindepth 3 -maxdepth 4 -type d \( -name include -o -path '*/include/eigen3' \) -print | LC_ALL=C sort -u)"

if [[ -z "$headers" ]]; then
  echo 'No AMSC package headers found' >&2
  exit 1
fi

cat <<'EOF'
# Managed by mac-sync for container-backed editing in ~/shared-folder.
# Linux include paths are discovered from the installed AMSC packages.
CompileFlags:
  Add:
EOF

while IFS= read -r directory; do
  printf '    - -I%s\n' "$directory"
done <<< "$headers"

cat <<'EOF'
---
If:
  PathMatch: .*\.c
CompileFlags:
  Compiler: /u/sw/toolchains/gcc-glibc/11.2.0/prefix/bin/gcc
---
If:
  PathMatch: .*\.(cc|cpp|cxx|C)
CompileFlags:
  Compiler: /u/sw/toolchains/gcc-glibc/11.2.0/prefix/bin/g++
EOF
