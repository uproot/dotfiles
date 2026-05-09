{ ... }:
let
  palette = import ./palette.nix;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = [ "--all" ];

    settings = {
      "$mod" = "SUPER";
      "$launch" = "ALT";
      "$term" = "alacritty";
      "$browser" = "chromium";
      "$fileManager" = "nautilus";

      env = [
        # Cursor + GTK theme match the user's GNOME session
        # (modules/home-manager/gnome/dconf.nix sets the same values), so the
        # look stays consistent across both compositors.
        "XCURSOR_THEME,phinger-cursors-dark"
        "XCURSOR_SIZE,24"
        "GTK_THEME,Adwaita-dark"
        "QT_QPA_PLATFORMTHEME,gtk3"
        "QT_QPA_PLATFORM,wayland;xcb"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        # Quickshell's matugen pipeline calls into a uv-managed venv at this
        # path on first run.  Stored as `~` because the shell scripts that
        # consume this var pipe it through `eval echo`, which expands tildes.
        "ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv"
      ];

      exec-once = [
        "gnome-keyring-daemon --start --components=secrets,ssh,pkcs11"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"

        # Desktop shell — vendored end-4/dots-hyprland under
        # modules/home-manager/wayland/quickshell/, exposed as the `ii` config.
        "qs -c ii"
      ];

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = palette.hypr.activeBorder;
        "col.inactive_border" = palette.hypr.inactiveBorder;
        layout = "dwindle";
        resize_on_border = true;
        extend_border_grab_area = 12;
        hover_icon_on_border = true;
        allow_tearing = false;
      };

      decoration = {
        rounding = 12;
        active_opacity = 1.0;
        inactive_opacity = 0.96;
        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };
        shadow = {
          enabled = true;
          range = 16;
          render_power = 3;
          color = palette.hypr.shadow;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "smooth,    0.25, 0.46, 0.45, 0.94"
          "snappy,    0.20, 0.90, 0.10, 1.05"
          "wind,      0.16, 1.00, 0.30, 1.00"
          "winIn,     0.05, 0.90, 0.10, 1.05"
          "winOut,    0.45, 0.00, 0.55, 1.00"
          "overshot,  0.13, 0.99, 0.29, 1.10"
        ];
        animation = [
          "windows,         1, 3, winIn,    popin 92%"
          "windowsOut,      1, 3, winOut,   popin 92%"
          "windowsMove,     1, 4, wind"
          "border,          1, 8, default"
          "borderangle,     1, 50, default, loop"
          "fade,            1, 4, smooth"
          "workspaces,      1, 3, overshot, slidefade 15%"
          "specialWorkspace,1, 3, overshot, slidefadevert 15%"
          "layers,          1, 3, smooth,   popin 95%"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad.natural_scroll = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        animate_manual_resizes = true;
        enable_swallow = true;
      };

      monitor = [
        "DP-1, 1920x1080@60,  0x0,    1"
        "DP-3, 1920x1080@165, 1920x0, 1"
        # Fallback for any other monitor (e.g. laptop panel) that gets attached later
        ", preferred, auto, 1"
      ];

      # One workspace pinned to the leftmost monitor (DP-1); the rest live on DP-3.
      # `default:true` ensures the workspace is materialized on its monitor at startup;
      # `persistent:true` keeps it alive even when empty so the bar always shows it.
      workspace = [
        "1, monitor:DP-1, default:true,  persistent:true"
        "2, monitor:DP-3, default:true,  persistent:true"
        "3, monitor:DP-3, persistent:true"
        "4, monitor:DP-3, persistent:true"
        "5, monitor:DP-3, persistent:true"
        "6, monitor:DP-3, persistent:true"
      ];
      # Bindings are organised in three layers:
      #   1. Window/workspace management (compositor-only, no shell deps).
      #   2. Application launchers (`$launch` = ALT, distinct from `$mod` so
      #      they never collide with Quickshell shell binds).
      #   3. Quickshell shell binds — paired via the `global, quickshell:<name>`
      #      mechanism with `exec` fallbacks gated on `qs -c ii ipc call
      #      TEST_ALIVE`.  When the shell is up the global handler fires and
      #      the fallback short-circuits; when it's down only the fallback
      #      runs (fuzzel / cliphist / brightnessctl / our screenshot scripts).
      bind = [
        # ── Window mgmt ────────────────────────────────────────────────
        "$mod, Q, killactive,"
        "$mod SHIFT, E, exit,"
        "$mod, F, fullscreen,"
        "$mod, L, exec, hyprlock"
        "$mod, P, pseudo,"
        "$mod, I, togglesplit,"
        "$mod, Space, togglefloating,"
        "$mod SHIFT, C, centerwindow,"

        "$mod, left,  movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up,    movefocus, u"
        "$mod, down,  movefocus, d"

        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"

        "$mod CTRL, h, resizeactive, -40 0"
        "$mod CTRL, l, resizeactive,  40 0"
        "$mod CTRL, k, resizeactive,  0 -40"
        "$mod CTRL, j, resizeactive,  0  40"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"

        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up,   workspace, e-1"

        # ── App launchers (distinct mod prefix to avoid shell conflicts) ─
        "$launch, T, exec, $term"
        "$launch, E, exec, $fileManager"
        "$launch, B, exec, $browser"

        # ── Quickshell shell — one-shot toggles ────────────────────────
        "$mod,        A,      global, quickshell:sidebarLeftToggle"
        "$mod,        N,      global, quickshell:sidebarRightToggle"
        "$mod,        slash,  global, quickshell:cheatsheetToggle"
        "$mod,        M,      global, quickshell:mediaControlsToggle"
        "$mod,        J,      global, quickshell:barToggle"
        "$mod,        G,      global, quickshell:overlayToggle"
        "$mod,        K,      global, quickshell:oskToggle"
        "$mod,        Tab,    global, quickshell:overviewWorkspacesToggle"
        "Ctrl Alt,    Delete, global, quickshell:sessionToggle"
        "Ctrl $mod,   T,      global, quickshell:wallpaperSelectorToggle"
        "Ctrl $mod Alt, T,    global, quickshell:wallpaperSelectorRandom"
        "Ctrl $mod,   P,      global, quickshell:panelFamilyCycle"
        "Ctrl $mod,   R,      exec,   killall qs quickshell; qs -c ii &"

        # Standalone settings window (Quickshell loads `settings.qml`).
        "$mod, S, exec, qs -p ~/.config/quickshell/ii/settings.qml"

        # ── Quickshell shell — overview tabs (with fuzzel/cliphist fallbacks) ─
        "$mod, V, global, quickshell:overviewClipboardToggle"
        "$mod, V, exec, qs -c ii ipc call TEST_ALIVE || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"

        "$mod, period, global, quickshell:overviewEmojiToggle"

        # ── Region / screenshot tools ──────────────────────────────────
        "$mod SHIFT, S, global, quickshell:regionScreenshot"
        "$mod SHIFT, S, exec, qs -c ii ipc call TEST_ALIVE || screenshot-region"

        "$mod SHIFT, A, global, quickshell:regionSearch" # Google Lens
        "$mod SHIFT, X, global, quickshell:regionOcr" # OCR → clipboard
        "$mod SHIFT, T, global, quickshell:screenTranslate" # On-screen translate

        # Fullscreen screenshot — always available, never goes through shell.
        "SHIFT, Print, exec, screenshot-full"
      ];

      bindl = [
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
        # Screen recording (lockable so it survives lockscreen).
        "$mod SHIFT, R, global, quickshell:regionRecord"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindr = [
        # Tap-Super → launcher (Quickshell `search` panel).  Falls back to
        # fuzzel if Quickshell isn't running.
        "SUPER, SUPER_L, global, quickshell:searchToggleRelease"
      ];

      bindel = [
        ",XF86AudioRaiseVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute,         exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle"
        # Brightness keys: try Quickshell's brightness IPC first (drives the
        # OSD), fall back to brightnessctl when the shell is down.
        ",XF86MonBrightnessUp,   exec, qs -c ii ipc call brightness increment || brightnessctl s 5%+"
        ",XF86MonBrightnessDown, exec, qs -c ii ipc call brightness decrement || brightnessctl s 5%-"
      ];
    };
  };
}
