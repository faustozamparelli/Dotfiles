#!/usr/bin/env bash
set -euo pipefail

# Official OpenCFD v2306 image, pinned to its Apple-silicon manifest.
image="opencfd/openfoam-default@sha256:7df8c49ff2f966deb0d8afba54a5deb19befc93ea4346e974f0f13869572c289"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ "${1:-}" == --run ]]; then
  shift
  # Bash preserves the entrypoint's temporary positional arguments while it
  # sources profile.rc. Ubuntu's /bin/sh can execute `bash -c` commands twice.
  args=(run --rm -i --platform linux/arm64 --entrypoint /bin/bash --user "$(id -u):$(id -g)")
  if [[ -t 0 && -t 1 ]]; then
    args+=(-t)
  fi
  # The image's entrypoint sets HOME and changes directory to /home/openfoam.
  # Bind only the current case directory; its files survive container removal.
  args+=(--mount "type=bind,src=$(pwd -P),dst=/home/openfoam" --workdir /home/openfoam)
  exec docker "${args[@]}" "$image" /openfoam/run "$@"
fi

if [[ "$(uname -m)" != arm64 ]]; then
  echo "This pinned OpenFOAM installer requires Apple silicon." >&2
  exit 1
fi

launcher="$HOME/.local/bin/openfoam2306"
mkdir -p "$HOME/.local/bin"
if [[ -e "$launcher" ]] &&
   ! grep -Fq '# Managed by mac-sync: OpenFOAM v2306.' "$launcher"; then
  echo "Refusing to replace an unmanaged $launcher." >&2
  exit 1
fi
cat > "$launcher" <<'LAUNCHER'
#!/usr/bin/env bash
# Managed by mac-sync: OpenFOAM v2306.
exec "$HOME/.config/mac-setup/direct/openfoam2306.sh" --run "$@"
LAUNCHER
chmod +x "$launcher"
