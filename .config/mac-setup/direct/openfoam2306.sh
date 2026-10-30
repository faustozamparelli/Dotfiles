#!/usr/bin/env bash
set -euo pipefail

# Official OpenCFD v2306 image, pinned to its Apple-silicon manifest.
image="opencfd/openfoam-default@sha256:7df8c49ff2f966deb0d8afba54a5deb19befc93ea4346e974f0f13869572c289"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ "${1:-}" == --run ]]; then
  shift
  if ! docker info >/dev/null 2>&1; then
    orb start
  fi
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
if ! command -v docker >/dev/null || ! command -v orb >/dev/null; then
  echo "OpenFOAM v2306 requires the managed OrbStack installation." >&2
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

# Ordinary hourly sync must not start a stopped Linux engine.
if docker info >/dev/null 2>&1; then
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    docker pull --platform linux/arm64 "$image"
  fi
else
  echo "OpenFOAM launcher ready; openfoam2306 starts OrbStack and pulls the pinned image if needed."
fi
