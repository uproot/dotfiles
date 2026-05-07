{ inputs, pkgs, ... }:

let
  astalPkgs = inputs.astal.packages.${pkgs.system};
in
{
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;
    configDir = ./config;
    # Launched via Hyprland exec-once instead of a systemd unit
    systemd.enable = false;
    extraPackages = with astalPkgs; [
      hyprland
      tray
      wireplumber
      mpris
      network
      notifd
      apps
      battery
      io
    ];
  };
}
