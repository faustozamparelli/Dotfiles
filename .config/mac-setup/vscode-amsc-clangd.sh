#!/usr/bin/env bash
set -eo pipefail
# Installed in the course container by vscode-amsc.py. Modules may reference
# unset variables, so nounset is deliberately not used while loading them.
source /u/sw/etc/profile.d/mk.sh
module load gcc-glibc/11.2.0 >&2
exec /usr/bin/clangd "$@"
