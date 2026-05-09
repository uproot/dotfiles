{ config, inputs, pkgs, lib, ... }:

# Quickshell desktop shell built on top of vendored end-4/dots-hyprland.
#
# The runtime config dir is `~/.config/quickshell/ii/`.  We assemble it from
# two sources:
#   • `./ii/`        — vendored upstream tree (modules/, services/, etc.)
#   • `./shell.qml`  — OUR custom entry, overlays end-4's shell.qml
#   • `./overrides/` — empty placeholder for component swaps
#
# Every entry is mounted via `mkOutOfStoreSymlink`, so edits in this repo
# take effect live (Quickshell reloads on file change — no rebuild needed
# for QML changes).
let
  qs = inputs.quickshell.packages.${pkgs.system}.default;

  # Wrap qs so Qt6 finds the QML modules end-4's shell imports.
  # `qt6.wrapQtAppsHook` is a postFixup hook that scans `buildInputs` for Qt
  # plugins/QML modules and injects the matching `QT_PLUGIN_PATH` /
  # `QML2_IMPORT_PATH` into the wrapper.  This MUST be a `stdenv.mkDerivation`
  # — `symlinkJoin` doesn't trigger the hook and leaves the wrap empty, which
  # is why earlier the shell crashed on `Qt5Compat.GraphicalEffects` etc.
  # Mirrors end-4's reference flake (sdata/dist-nix/home-manager/quickshell.nix).
  quickshellWrapped = pkgs.stdenv.mkDerivation {
    name = "quickshell-ii";

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [ pkgs.makeWrapper pkgs.qt6.wrapQtAppsHook ];
    buildInputs = with pkgs; [
      qs
      kdePackages.qtwayland
      kdePackages.qtpositioning
      kdePackages.qtlocation
      kdePackages.syntax-highlighting
      kdePackages.kirigami
      gsettings-desktop-schemas
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qt5compat
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qtpositioning
      qt6.qtquicktimeline
      qt6.qtsensors
      qt6.qtsvg
      qt6.qttools
      qt6.qttranslations
      qt6.qtvirtualkeyboard
      qt6.qtwayland
    ];

    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${qs}/bin/qs $out/bin/qs \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}
    '';
  };

  # Absolute path to this directory in the user's checkout.  Required by
  # mkOutOfStoreSymlink so edits remain live (the symlink target is the
  # real working tree, not a /nix/store copy).
  repoDir = "${config.home.homeDirectory}/dotfiles/modules/home-manager/wayland/quickshell";

  # Top-level files under ii/ (everything except shell.qml, which our
  # custom file replaces at runtime).
  iiTopLevelFiles = [
    "GlobalStates.qml"
    "ReloadPopup.qml"
    "killDialog.qml"
    "settings.qml"
    "welcome.qml"
  ];

  # Top-level dirs under ii/ — symlinked wholesale.
  iiTopLevelDirs = [
    "assets"
    "defaults"
    "modules"
    "panelFamilies"
    "scripts"
    "services"
    "translations"
  ];

  mkSymlink = repoSubpath: config.lib.file.mkOutOfStoreSymlink "${repoDir}/${repoSubpath}";

  iiFileEntries = lib.listToAttrs (map
    (name: lib.nameValuePair "quickshell/ii/${name}" {
      source = mkSymlink "ii/${name}";
    })
    iiTopLevelFiles);

  iiDirEntries = lib.listToAttrs (map
    (name: lib.nameValuePair "quickshell/ii/${name}" {
      source = mkSymlink "ii/${name}";
    })
    iiTopLevelDirs);

  customEntries = {
    # Our custom shell.qml replaces end-4's at runtime.
    "quickshell/ii/shell.qml".source = mkSymlink "shell.qml";
    # Overrides folder, accessible to QML as `import "overrides"`.
    "quickshell/ii/overrides".source = mkSymlink "overrides";
    # Preserve end-4's original shell.qml as a reference companion
    # (renamed so it doesn't clash with ours).  Editable too.
    "quickshell/ii/shell.upstream.qml".source = mkSymlink "ii/shell.qml";
  };
in
{
  xdg.configFile = iiFileEntries // iiDirEntries // customEntries;

  # Expose Quickshell's QML modules + the vendored shell tree to qmlls (and
  # any other QML tooling).  qt-qml reads this when its
  # `useQmlImportPathEnvVar` setting is true (configured globally in
  # modules/home-manager/development/vscode.nix and per-project in
  # .vscode/settings.json).
  home.sessionVariables = {
    QML_IMPORT_PATH = "${qs}/lib/qt-6/qml";
    QML2_IMPORT_PATH = "${qs}/lib/qt-6/qml";
  };

  # Runtime dependencies the shell expects on PATH.  Cross-referenced from
  # end-4's `sdata/dist-nix/home-manager/home.nix`.  Items already provided
  # by sibling modules (services.nix, terminals/, gnome/, etc.) are noted.
  home.packages = with pkgs; [
    quickshellWrapped

    # ── Audio / media ────────────────────────────────────────────────
    libcava # cava visualiser (bar widget)
    lxqt.pavucontrol-qt # pavucontrol-qt (audio settings shortcut)
    libdbusmenu-gtk3 # tray icons that use dbusmenu-gtk
    # wireplumber / pipewire / playerctl / libnotify already enabled at
    # the system level (modules/nixos/audio.nix) and in services.nix.

    # ── Backlight / sensors ─────────────────────────────────────────
    (geoclue2.override { withDemoAgent = true; }) # night-light location
    ddcutil # external-monitor brightness via DDC/CI
    # brightnessctl is in services.nix.

    # ── Basic CLI tools the shell shells out to ──────────────────────
    bc
    ripgrep
    jq
    yq-go
    rsync
    curlFull
    wget
    xdg-user-dirs

    # ── Icons / GTK theme ───────────────────────────────────────────
    # Cursor (phinger-cursors) comes from gnome/extensions.nix so it's
    # consistent across GNOME and Hyprland sessions.
    adw-gtk3
    kdePackages.breeze
    kdePackages.breeze-icons
    darkly
    darkly-qt5

    # ── Fonts the shell hard-codes ──────────────────────────────────
    # Local font defaults (set in `ii/modules/common/Config.qml`) point
    # main/numbers/title/reading/expressive at Inter; monospace/iconNerd
    # at JetBrains Mono Nerd; emoji at Twemoji + Noto Color Emoji.
    inter
    nerd-fonts.jetbrains-mono
    material-symbols
    twemoji-color-font
    noto-fonts-color-emoji
    fontconfig

    # ── Hyprland companions ─────────────────────────────────────────
    hyprsunset
    hyprshot
    hyprpicker
    wlogout
    # hypridle / hyprlock are configured in services.nix.
    # wl-clipboard / cliphist / grim / slurp live in services.nix.

    # ── Region / screenshot tools ───────────────────────────────────
    swappy
    tesseract
    wf-recorder
    songrec

    # ── Launcher / picker fallbacks (also used by end-4 keybinds) ───
    fuzzel
    libqalculate # qalc, used by Quickshell calculator widget
    imagemagick
    glib # gdbus, gsettings
    upower
    wtype
    ydotool

    # ── Material colour pipeline ────────────────────────────────────
    matugen
    uv # bootstraps the Python venv at first run
    gtk4
    libadwaita
    libsoup_3
    libportal-gtk4
    gobject-introspection

    # ── Translation / accessibility ─────────────────────────────────
    translate-shell

    # ── KDE bits the shell relies on ────────────────────────────────
    kdePackages.bluedevil
    kdePackages.plasma-nm
    kdePackages.kdialog
  ];

  fonts.fontconfig.enable = true;
}
