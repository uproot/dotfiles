{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    fontconfig.defaultFonts = {
      sansSerif = [ "Inter" "Noto Sans" ];
      serif = [ "Inter" "Noto Serif" ];
      monospace = [ "JetBrains Mono NF" ];
    };
    packages = with pkgs; [
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      inter
    ];
  };
}
