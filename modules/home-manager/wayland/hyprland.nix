{ ... }:
let
  palette = import ./palette.nix;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = [ "--all" ];

    settings = {
      monitor = [
        "DP-3, 1920x1080@165, 1920x0, 1"
        "DP-1, 1920x1080@60, 0x0, 1"
      ];

      "$mod" = "SUPER";
      "$launch" = "ALT";
      "$term" = "alacritty";
      "$browser" = "chromium";
      "$fileManager" = "nautilus";

      env = [
        "XCURSOR_THEME,phinger-cursors-dark"
        "XCURSOR_SIZE,24"
        "GTK_THEME,Adwaita-dark"
        "QT_QPA_PLATFORMTHEME,gtk3"
      ];

      exec-once = [
        "gnome-keyring-daemon --start --components=secrets,ssh,pkcs11"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"

        # Desktop shell
        "ags run"

        # Initialize Wallpaper Daemon
        "awww-daemon"
        "bash -c 'sleep 2 && awww img ~/.background-image --transition-type fade'"
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

      workspace = [
        "1, monitor:DP-3, persistent:true, default:true"
        "2, monitor:DP-3, persistent:true"
        "3, monitor:DP-3, persistent:true"
        "4, monitor:DP-3"
        "5, monitor:DP-3"
        "6, monitor:DP-1, persistent:true, default:true"
      ];

      bind = [
        "$launch, T, exec, $term"
        "$mod, Q, killactive,"
        "$mod SHIFT, E, exit,"
        "$launch, E, exec, $fileManager"
        "$launch, B, exec, $browser"
        "$mod, F, fullscreen,"
        "$mod, L, exec, hyprlock"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"
        "$mod, Space, togglefloating,"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"

        "$mod CTRL, h, resizeactive, -40 0"
        "$mod CTRL, l, resizeactive,  40 0"
        "$mod CTRL, k, resizeactive,  0 -40"
        "$mod CTRL, j, resizeactive,  0  40"

        "$mod SHIFT, C, centerwindow,"

        "$mod, a, workspace, m-1"
        "$mod, d, workspace, m+1"

        "$mod SHIFT, a, movetoworkspace, m-1"
        "$mod SHIFT, d, movetoworkspace, m+1"

        "$mod, S, exec, ags request toggle settings"
        "$mod, N, exec, ags request toggle notification-center"
        "$mod, V, exec, ags request toggle clipboard"
        "$mod, period, exec, ags request toggle emoji"

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

        "$mod, mouse_down, workspace, m+1"
        "$mod, mouse_up, workspace, m-1"

        # Screenshots: Shift+Print → fullscreen, Super+Shift+S → quick region
        "SHIFT, Print, exec, screenshot-full"
        "$mod SHIFT, S, exec, screenshot-region"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindr = [
        "SUPER, SUPER_L, exec, ags request toggle launcher"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute,        exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86MonBrightnessUp,  exec, brightnessctl s 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 5%-"
      ];

      bindl = [
        ",XF86AudioPlay,  exec, playerctl play-pause"
        ",XF86AudioNext,  exec, playerctl next"
        ",XF86AudioPrev,  exec, playerctl previous"
      ];
    };
  };
}
