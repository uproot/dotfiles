# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
sudo nixos-rebuild switch --flake .#computer   # apply system + home-manager
sudo nixos-rebuild test   --flake .#computer   # try without making it the default boot entry
nix flake update                                # bump all inputs
nix flake update <input>                        # bump one input (e.g. nixpkgs, ags, quickshell)

nix run nixpkgs#statix -- check .              # lint Nix
nix run nixpkgs#nixpkgs-fmt -- .               # format Nix
```

There is one NixOS configuration: `nixosConfigurations.computer` (single host, `x86_64-linux`). The `result` symlink at the repo root is the last build output and is gitignored.

`statix.toml` ignores `**/hardware.nix` (auto-generated).

## Architecture

### Flake composition (`flake.nix`)

The flake passes `inputs` through `specialArgs` / `extraSpecialArgs`, so any module can take `{ inputs, ... }` and reach things like `inputs.astal.packages.${pkgs.system}` or `inputs.ags.homeManagerModules.default` directly. All third-party inputs use `inputs.nixpkgs.follows = "nixpkgs"` to keep the closure small — preserve that when adding inputs.

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

### Wayland session (Hyprland + AGS)

`modules/home-manager/wayland/` is a self-contained desktop shell:

- `hyprland.nix` — Hyprland config. `$term = alacritty`, `$browser = chromium`, `$fileManager = nautilus`. `exec-once` starts `swww-daemon` (wallpaper daemon) with a fade transition to `assets/wallpaper.png`, `gnome-keyring-daemon`, and two `wl-paste`/`cliphist` watchers. The tap-Super keybind (`bindr`) talks to AGS via `ags request 'toggle launcher'`.
- `palette.nix` — single source of truth for colors (monochrome black/white). Imported by `hyprland.nix` and the AGS SCSS. **Edit colors here, not in individual modules.**
- `ags/default.nix` — wires `programs.ags` (from the `ags` flake input) and lists the Astal sub-packages (`hyprland`, `tray`, `wireplumber`, `mpris`, `network`, `notifd`, `apps`, `battery`, `io`) that the TS code is allowed to import. Adding a new Astal binding requires adding it here too.
- `ags/config/` — the AGS v3 TypeScript/JSX shell (GTK4). `app.tsx` is the entry point; widgets live under `widget/`. JSX uses `jsxImportSource: "ags/gtk4"`. There is no separate build step — AGS compiles on launch from the home-manager-installed `configDir`.
- `services.nix` — adjacent Wayland services (hyprlock, hyprpaper, etc.).

Inter-process control: `app.tsx` registers a `requestHandler` that accepts `toggle <window-name>`. To trigger UI from elsewhere (Hyprland binds, scripts), use `ags request 'toggle <name>'` rather than spawning new processes.

Note on the in-flight migration: `flake.nix` carries both `astal`/`ags` and `quickshell` inputs. AGS is the active shell on this branch (`hyprland-astal`); Quickshell is staged for a future swap (`exec-once = [ ... "qs" ... ]` already starts it). When changing shell behavior, prefer editing the AGS config unless the task is specifically about the Quickshell migration.

### Terminals

`modules/home-manager/terminals/` enables `alacritty`, `wezterm`, and `foot` in parallel. Hyprland's `$term` chooses which one `$mod+Return` launches — change it there, not by removing modules.
