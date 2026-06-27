# wwn-kmscube

Wawona's port of [kmscube](https://gitlab.freedesktop.org/mesa/kmscube) — the canonical GBM/EGL/DRM spinning-cube GL smoke test. Built **in-process** as `libkmscube.a` (`kmscube_main`) on Apple mobile and Android, and as a standalone `kmscube` binary on macOS for local testing.

KMS/GBM/EGL/DRM come from [wwn-iland](https://github.com/Wawona/wwn-iland) (IOSurface + ANGLE on Apple). This repo owns the kmscube program sources and Nix cross-build recipes; it does not vendor iland.

## Outputs

| Artifact | Description |
|----------|-------------|
| `libkmscube.a` | In-process archive; `main` renamed to `kmscube_main` |
| `kmscube` (macOS) | Standalone binary linked against iland + ANGLE |
| `include/kmscube.h` | `kmscube_main` declaration for app linkers |

## Nix registry

`registryFragment` exposes:

| Attribute | Role |
|-----------|------|
| `kmscube` | Primary entry — all platform recipes |
| `iland-gl-clients` | Legacy alias (same recipes); kept for flakes that still use that name |

## Platform coverage

| Platform | Recipe | Notes |
|----------|--------|-------|
| iOS / iPadOS | `ios.nix` → `apple-mobile.nix` | `libkmscube.a` only |
| tvOS / watchOS / visionOS | re-export `ios.nix` | same archive model |
| macOS | `macos.nix` | binary + `libkmscube.a` |
| Android / Wear OS | `android.nix` | `libkmscube.a`; requires iland on Android |
| Linux | `linux.nix` | nixpkgs `kmscube` reference binary |

Sources live in `upstream/` (vendored from the iland kmscube test tree; `kmscube_compat.h` handles Apple EGL display typing).

## Use in a flake

```nix
inputs.wwn-kmscube.url = "github:Wawona/wwn-kmscube";

registry = wwn-toolchain.lib.baseRegistry
  // wwn-iland.registryFragment
  // wwn-kmscube.registryFragment;
```

Link helper for Xcode app targets: `dependencies/generators/kmscube-ldflags.nix` (iland + ANGLE + `-force_load libkmscube.a`).

## Standalone build

```sh
nix build .#kmscube-ios
nix build .#kmscube-macos
```

With Wawona's flake: `kmscube-ios`, `kmscube-macos`, `kmscube-android` (when iland Android is available).

## Layout

```
upstream/                    # kmscube.c, esUtil.c, compat header
dependencies/clients/kmscube/  # per-platform Nix recipes
dependencies/generators/       # kmscube-ldflags.nix
```

## License

MIT for Wawona packaging (see `LICENSE`). kmscube upstream is MIT; sources are vendored in `upstream/`.
