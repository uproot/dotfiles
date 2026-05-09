_: {
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require "wezterm"
      local config = wezterm.config_builder()

      config.font = wezterm.font("JetBrainsMono Nerd Font")
      config.font_size = 12.0

      config.color_scheme = nil
      config.colors = {
        foreground = "#e6e6e6",
        background = "#0e0e0e",
        cursor_bg = "#e6e6e6",
        cursor_fg = "#0e0e0e",
        cursor_border = "#e6e6e6",
        selection_fg = "#0e0e0e",
        selection_bg = "#bdbdbd",
        ansi = {
          "#1a1a1a", "#cc6666", "#a3be8c", "#d8a657",
          "#7aa2c7", "#b48ead", "#88c0d0", "#e6e6e6",
        },
        brights = {
          "#3a3a3a", "#e88080", "#b9d4a0", "#ecbf73",
          "#9bbfdf", "#cba6c3", "#a3d2dc", "#ffffff",
        },
      }

      config.window_background_opacity = 0.96
      config.window_decorations = "NONE"
      config.window_padding = {
        left = 14, right = 14, top = 12, bottom = 12,
      }

      config.enable_tab_bar = false
      config.hide_mouse_cursor_when_typing = true
      config.scrollback_lines = 10000
      config.audible_bell = "Disabled"

      config.default_cursor_style = "BlinkingBar"

      return config
    '';
  };
}
