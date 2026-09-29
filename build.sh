#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$ROOT_DIR/.tools"
REPAK="$TOOLS_DIR/bin/repak"
DOTNET="$TOOLS_DIR/dotnet/dotnet"
PROJECT="$ROOT_DIR/src/AstroneerMouseFix.Builder/AstroneerMouseFix.Builder.csproj"
PACKAGE_METADATA="$ROOT_DIR/package/metadata.json"

MOD_ID="$(sed -nE 's/^[[:space:]]*"mod_id"[[:space:]]*:[[:space:]]*"([^"]+)".*$/\1/p' "$PACKAGE_METADATA")"
MOD_VERSION="$(sed -nE 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*$/\1/p' "$PACKAGE_METADATA")"
if [[ -z "$MOD_ID" || -z "$MOD_VERSION" || "$MOD_ID" == *[!A-Za-z0-9._-]* || "$MOD_VERSION" == *[!A-Za-z0-9.+-]* ]]; then
    printf 'Package metadata contains a missing or filename-unsafe mod ID or version.\n' >&2
    exit 1
fi
OUTPUT_NAME="001-${MOD_ID}-${MOD_VERSION}_P.pak"

ASTRONEER_DIR="${ASTRONEER_DIR:-$HOME/.local/share/Steam/steamapps/common/ASTRONEER}"
ASTRONEER_SAVED_DIR="${ASTRONEER_SAVED_DIR:-$HOME/.local/share/Steam/steamapps/compatdata/361420/pfx/drive_c/users/steamuser/AppData/Local/Astro/Saved}"
GAME_PAK="$ASTRONEER_DIR/Astro/Content/Paks/pakchunk0-WindowsNoEditor.pak"
INSTALL=false

if [[ "${1:-}" == "--install" ]]; then
    INSTALL=true
elif [[ $# -ne 0 ]]; then
    printf 'Usage: %s [--install]\n' "$0" >&2
    exit 2
fi

if [[ ! -f "$GAME_PAK" ]]; then
    printf 'Astroneer game PAK was not found: %s\n' "$GAME_PAK" >&2
    printf 'Set ASTRONEER_DIR to the game installation directory.\n' >&2
    exit 1
fi

"$ROOT_DIR/scripts/bootstrap.sh"

export DOTNET_CLI_HOME="$TOOLS_DIR/dotnet-home"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export NUGET_PACKAGES="$TOOLS_DIR/nuget"

WORK_DIR="$(mktemp --directory "$ROOT_DIR/.build.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

STOCK_DIR="$WORK_DIR/stock/Astro/Content/Camera"
PACKAGE_DIR="$WORK_DIR/package/Astro/Content/Camera"
mkdir -p "$STOCK_DIR" "$PACKAGE_DIR" "$ROOT_DIR/dist"

for extension in uasset uexp; do
    asset_path="Astro/Content/Camera/CameraSpaceWalkingRig.$extension"
    "$REPAK" get "$GAME_PAK" "$asset_path" > "$STOCK_DIR/CameraSpaceWalkingRig.$extension"
done

"$DOTNET" restore "$PROJECT" --locked-mode
"$DOTNET" run --project "$PROJECT" --configuration Release --no-restore -- \
    "$STOCK_DIR/CameraSpaceWalkingRig.uasset" \
    "$PACKAGE_DIR/CameraSpaceWalkingRig.uasset"

cp "$PACKAGE_METADATA" "$WORK_DIR/package/metadata.json"
"$REPAK" pack --version V8B --mount-point ../../../ "$WORK_DIR/package" "$WORK_DIR/$OUTPUT_NAME"
install -m 0644 "$WORK_DIR/$OUTPUT_NAME" "$ROOT_DIR/dist/$OUTPUT_NAME"

if [[ "$INSTALL" == true ]]; then
    mkdir -p "$ASTRONEER_SAVED_DIR/Paks"
    install -m 0644 "$WORK_DIR/$OUTPUT_NAME" "$ASTRONEER_SAVED_DIR/Paks/$OUTPUT_NAME"
    printf 'Installed %s\n' "$ASTRONEER_SAVED_DIR/Paks/$OUTPUT_NAME"
else
    printf 'Built %s\n' "$ROOT_DIR/dist/$OUTPUT_NAME"
fi
