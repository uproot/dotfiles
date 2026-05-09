{ pkgs, lib, ... }:

let
  qmllsPath = "${pkgs.qt6.qtdeclarative}/bin/qmlls";

  settings = {
    # Nix LSP
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nixd";
    "nix.serverSettings"."nixd"."formatting"."command" = [ "nixpkgs-fmt" ];

    # Qt QML
    "qt-qml.qmlls.customExePath" = qmllsPath;
    "qt-qml.qmlls.useQmlImportPathEnvVar" = true;

    # Theme
    "workbench.colorTheme" = "Dark Modern";
    "workbench.iconTheme" = "material-icon-theme";

    # Editor — appearance
    "editor.fontFamily" = "'JetBrains Mono', monospace";
    "editor.fontSize" = 14;
    "editor.fontLigatures" = true;
    "editor.lineHeight" = 1.6;
    "editor.minimap.enabled" = false;
    "editor.renderWhitespace" = "boundary";
    "editor.smoothScrolling" = true;
    "editor.cursorBlinking" = "smooth";
    "editor.cursorSmoothCaretAnimation" = "on";
    "editor.bracketPairColorization.enabled" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.stickyScroll.enabled" = true;
    "editor.inlayHints.enabled" = "offUnlessPressed";

    # Editor — behaviour
    "editor.formatOnSave" = true;
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.wordWrap" = "off";
    "editor.inlineSuggest.enabled" = true;
    "editor.suggest.preview" = true;

    # Language-specific formatters
    "[javascript]" = { "editor.defaultFormatter" = "oxc.oxc-vscode"; };
    "[javascriptreact]" = { "editor.defaultFormatter" = "oxc.oxc-vscode"; };
    "[typescript]" = { "editor.defaultFormatter" = "oxc.oxc-vscode"; };
    "[typescriptreact]" = { "editor.defaultFormatter" = "oxc.oxc-vscode"; };
    "[json]" = { "editor.defaultFormatter" = "oxc.oxc-vscode"; };
    "[jsonc]" = { "editor.defaultFormatter" = "oxc.oxc-vscode"; };
    "[nix]" = { "editor.defaultFormatter" = "jnoortheen.nix-ide"; };

    # Workbench
    "workbench.startupEditor" = "none";
    "workbench.tree.indent" = 16;
    "workbench.smoothScrolling" = true;
    "workbench.list.smoothScrolling" = true;
    "workbench.editor.labelFormat" = "short";

    # Files
    "files.autoSave" = "onFocusChange";
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;

    # Terminal
    "terminal.integrated.fontSize" = 13;
    "terminal.integrated.smoothScrolling" = true;
    "terminal.integrated.cursorBlinking" = true;

    # Error Lens
    "errorLens.enabledDiagnosticLevels" = [ "error" "warning" "info" ];
    "errorLens.gutterIconsEnabled" = true;
    "errorLens.delay" = 200;

    # GitLens
    "gitlens.codeLens.enabled" = false;
    "gitlens.currentLine.enabled" = true;
    "gitlens.hovers.currentLine.over" = "line";

    # Git Graph
    "git-graph.date.format" = "Relative";

    # Indent Rainbow
    "indentRainbow.indicatorStyle" = "light";

    # Todo Tree
    "todo-tree.general.tags" = [ "TODO" "FIXME" "HACK" "NOTE" "BUG" ];
    "todo-tree.highlights.defaultHighlight" = {
      "icon" = "alert";
      "type" = "text";
    };

    # Explorer
    "explorer.confirmDelete" = false;
    "explorer.confirmDragAndDrop" = false;

    # Telemetry
    "telemetry.telemetryLevel" = "off";
  };

  settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON settings);
in

{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    extensions = with pkgs.vscode-extensions; [
      # Nix
      jnoortheen.nix-ide
      mkhl.direnv

      # Icons
      pkief.material-icon-theme

      # Git
      eamodio.gitlens
      mhutchie.git-graph
      (pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "vscode-conventional-commits";
        publisher = "vivaxy";
        version = "1.27.0";
        sha256 = "sha256-yZ3pVBJGcwSNlN7LvFppAuNomxlQDTvA42kUpsZLj7Y=";
      })

      # Error display
      usernamehw.errorlens

      # Formatting & Linting
      biomejs.biome
      esbenp.prettier-vscode
      (pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "oxc-vscode";
        publisher = "oxc";
        version = "1.53.0";
        sha256 = "sha256-CqEMaXg7JUzp1BMLCIyXKhqGCJbMbfPyzGFWKrVEhH4=";
      })

      # Language support
      bradlc.vscode-tailwindcss
      tamasfe.even-better-toml
      redhat.vscode-yaml
      rust-lang.rust-analyzer
      ms-python.python
      ms-python.vscode-pylance
      denoland.vscode-deno

      # Qt / QML
      (pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "qt-qml";
        publisher = "TheQtCompany";
        version = "1.13.0";
        sha256 = "sha256-WPzierXLQM+HdVb0XAx80f4Fdd34Vf7WbFzFapr5VHE=";
      })

      (pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "qt-core";
        publisher = "TheQtCompany";
        version = "1.13.0";
        sha256 = "sha256-/SAoJmKfOfLtbYn4jvtbAFIa6O7kDouv0xQVhnxFOKM=";
      })

      # HTML/CSS
      formulahendry.auto-rename-tag
      naumovs.color-highlight

      # Productivity
      christian-kohler.path-intellisense
      aaron-bond.better-comments
      gruntfuggly.todo-tree
      oderwat.indent-rainbow

      # Tools
      humao.rest-client
      ms-azuretools.vscode-docker

      # Claude Code
      (pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "claude-code";
        publisher = "anthropic";
        version = "2.1.114";
        sha256 = "sha256-TfVradC9ZjfLBp8QvZ0AptCS9j2ogzSlsRXxksp+N9I=";
      })
    ];
  };

  # Write settings as a writable file (not a store symlink) so VSCode can modify it.
  # The file is overwritten with Nix-defined settings on every rebuild.
  home.activation.vscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD install -Dm644 ${settingsFile} "$HOME/.config/Code/User/settings.json"
  '';
}
