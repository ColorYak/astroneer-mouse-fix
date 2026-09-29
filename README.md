# Astroneer Mouse Fix

A reproducible build for more direct and consistent mouse camera control in Astroneer.

The repository does not include Astroneer assets. The build extracts `CameraSpaceWalkingRig` from your installed game, changes a small set of numeric defaults, and packages the modified asset locally.

## Changes

The mod:

- Makes horizontal and vertical mouse movement respond at the same rate.
- Removes mouse-input smoothing and delayed camera settling.

## Requirements

- Linux x86-64
- An installed Steam copy of Astroneer
- `curl`, `tar`, `sed`, `sha256sum`, and `sha512sum`

The bootstrap script downloads pinned copies of repak and the .NET SDK into `.tools/`. NuGet restores the pinned UAssetAPI package into the same ignored directory.

## Build

```bash
./build.sh
```

The package is written to `dist/001-{mod-id}-{version}_P.pak`, using the values from `package/metadata.json`.

The default game path is:

```text
~/.local/share/Steam/steamapps/common/ASTRONEER
```

Set `ASTRONEER_DIR` when the game uses another library:

```bash
ASTRONEER_DIR="/path/to/ASTRONEER" ./build.sh
```

## Install

Build and install into the default Proton prefix:

```bash
./build.sh --install
```

Set `ASTRONEER_SAVED_DIR` to override the default saved-data path:

```bash
ASTRONEER_SAVED_DIR="/path/to/Astro/Saved" ./build.sh --install
```

## Tested version

Astroneer `1.44.4.0` on Linux through Steam Proton.
