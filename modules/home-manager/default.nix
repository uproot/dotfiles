_:

{
  imports = [
    ./gnome/extensions.nix
    ./gnome/dconf.nix
    ./browsers
    ./development
    ./shell.nix
    ./apps
    ./wayland
    ./terminals
  ];

  home = {
    username = "user";
    homeDirectory = "/home/user";
    stateVersion = "25.11";
  };

  # Write ~/.config/nixpkgs/config.nix so ad-hoc nix commands
  # (nix run, nix shell, etc.) allow unfree packages without env vars
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  programs.home-manager.enable = true;
}
