_: {
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 14;
          y = 12;
        };
        dynamic_padding = true;
        opacity = 0.96;
        decorations = "none";
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 12.0;
      };

      cursor = {
        style = {
          shape = "Beam";
          blinking = "On";
        };
        unfocused_hollow = true;
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      colors = {
        primary = {
          background = "#0e0e0e";
          foreground = "#e6e6e6";
        };
        cursor = {
          text = "#0e0e0e";
          cursor = "#e6e6e6";
        };
        normal = {
          black = "#1a1a1a";
          red = "#cc6666";
          green = "#a3be8c";
          yellow = "#d8a657";
          blue = "#7aa2c7";
          magenta = "#b48ead";
          cyan = "#88c0d0";
          white = "#e6e6e6";
        };
        bright = {
          black = "#3a3a3a";
          red = "#e88080";
          green = "#b9d4a0";
          yellow = "#ecbf73";
          blue = "#9bbfdf";
          magenta = "#cba6c3";
          cyan = "#a3d2dc";
          white = "#ffffff";
        };
      };
    };
  };
}
