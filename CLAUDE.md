# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
sudo nixos-rebuild switch --flake .#computer   # apply system + home-manager
sudo nixos-rebuild test   --flake .#computer   # try without making it the default boot entry
nix flake update                                # bump all inputs
nix flake update <input>                        # bump one input (e.g. nixpkgs, quickshell)

nix run nixpkgs#statix -- check .              # lint Nix
nix run nixpkgs#nixpkgs-fmt -- .               # format Nix
```

There is one NixOS configuration: `nixosConfigurations.computer` (single host, `x86_64-linux`). The `result` symlink at the repo root is the last build output and is gitignored.

`statix.toml` ignores `**/hardware.nix` (auto-generated).

## Architecture

### Flake composition (`flake.nix`)

The flake passes `inputs` through `specialArgs` / `extraSpecialArgs`, so any module can take `{ inputs, ... }` and reach things like `inputs.quickshell.packages.${pkgs.system}.default` directly. All third-party inputs use `inputs.nixpkgs.follows = "nixpkgs"` to keep the closure small — preserve that when adding inputs.

The `quickshell` input is **rev-pinned** to the commit end-4/dots-hyprland tests against (see `flake.nix` comment). Bump it in lockstep with the vendored `modules/home-manager/wayland/quickshell/ii/` tree, otherwise the QML may reference modules that don't exist in the runtime.

Three overlays are applied at the top level:
- `claude-code.overlays.default` (from `claude-code-nix`) — provides `pkgs.claude-code`.
- `nur.overlays.default` — used by the LibreWolf module for Firefox add-ons.
- A local overlay exposing `pkgs.oxlint-latest` from `pkgs/oxlint-latest/` (a versioned override of `oxlint`).

Home-manager runs as a NixOS module (`useGlobalPkgs = true; useUserPackages = true;`) for user `user`, importing `./modules/home-manager` as the user config.

### Module layout

- `hosts/computer/` — host entry point + generated `hardware.nix`. Sets `system.stateVersion`. Imports `modules/nixos`.
- `modules/nixos/default.nix` — barrel that imports every system module (`boot`, `networking`, `audio`, `gnome`, `hyprland`, `nvidia`, `gaming`, `virtualisation`, `vpn`, `printing`, `nix-ld`, …). Both GNOME and Hyprland are enabled at the system level; the user picks at the display manager.
- `modules/home-manager/default.nix` — barrel for the user side. Imports `gnome/{extensions,dconf}`, `browsers`, `development`, `shell.nix`, `apps`, `wayland`, `terminals`. Also writes `~/.config/nixpkgs/config.nix` so ad-hoc `nix run`/`nix shell` allow unfree without env vars.

When adding a new module, drop it in the appropriate subtree and add it to that subtree's `default.nix` barrel — there is no auto-discovery.

### Wayland session (Hyprland + Quickshell)

`modules/home-manager/wayland/` is a self-contained desktop shell:

- `hyprland.nix` — Hyprland config. `$term = alacritty`, `$browser = chromium`, `$fileManager = nautilus`. `exec-once` starts `qs -c ii` (the Quickshell shell), `awww-daemon` (wallpaper) with a fade transition to `assets/wallpaper.png`, `gnome-keyring-daemon`, and two `wl-paste`/`cliphist` watchers. Shell-aware binds use `bind = …, global, quickshell:<shortcutName>` paired with `exec` fallbacks gated on `qs -c ii ipc call TEST_ALIVE` so they degrade to `fuzzel`/`cliphist`/`brightnessctl` when the shell isn't running.
- `palette.nix` — single source of truth for hyprland/hyprlock colors (monochrome black/white). Imported by `hyprland.nix` and `services.nix`. The Quickshell shell has its own theme system driven by matugen; edit `~/.config/illogical-impulse/config.json` (or the in-shell settings UI) for shell colors. **For Hyprland-side colors, edit `palette.nix`, not individual modules.**
- `quickshell/default.nix` — home-manager wiring. Wraps `inputs.quickshell.packages.<sys>.default` with the Qt plugins end-4's QML imports, then assembles `~/.config/quickshell/ii/` as out-of-store symlinks pointing back into this directory (so QML edits hot-reload from the working tree). Also installs all runtime deps the shell shells out to (matugen, fuzzel, hyprshot, hyprpicker, wlogout, songrec, tesseract, libqalculate, …).
- `quickshell/shell.qml` — OUR custom shell entry. At runtime it overlays end-4's `ii/shell.qml` (the original is preserved as `~/.config/quickshell/ii/shell.upstream.qml`). Trim panel families or wire in custom imports here.
- `quickshell/ii/` — vendored `dots/.config/quickshell/ii/` from `github:end-4/dots-hyprland`. Edit it directly; nothing in here is built from a flake input. Bump in lockstep with the `quickshell` input rev-pin in `flake.nix`.
- `quickshell/overrides/` — drop QML files here for selective component overrides (mounted as `~/.config/quickshell/ii/overrides/`).
- `services.nix` — adjacent Wayland services (`hypridle`, `hyprlock`, screenshot scripts, awww wallpaper daemon).

Inter-process control: shell-side `IpcHandler` and `GlobalShortcut` blocks accept `qs -c ii ipc call <target> <fn>` and `bind = …, global, quickshell:<name>` from Hyprland. IPC targets live in `quickshell/ii/services/*.qml` and the per-panel-family modules. To wire a new bind, prefer the `global, quickshell:<name>` form (registered via `GlobalShortcut { name: ... }` in QML) over spawning a new process — see existing examples in `hyprland.nix`.

### Terminals

`modules/home-manager/terminals/` enables `alacritty`, `wezterm`, and `foot` in parallel. Hyprland's `$term` chooses which one `$mod+Return` launches — change it there, not by removing modules.
