{ pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    printing.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    evince
    totem
    gnome-music
    gnome-characters
  ];

  environment.systemPackages = with pkgs; [
    zenity
  ];
}
