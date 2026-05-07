{
  description = "yusof's nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code.url = "github:sadjow/claude-code-nix";

    nur.url = "github:nix-community/NUR";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    minegrub-world-sel-theme = {
      url = "github:Lxtharia/minegrub-world-sel-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Astal libraries used by the AGS desktop shell
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, claude-code, nur, nix-index-database, ... }@inputs: {
    nixosConfigurations.computer = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/computer
        inputs.minegrub-world-sel-theme.nixosModules.default

        {
          nixpkgs.overlays = [
            claude-code.overlays.default
            nur.overlays.default
            (final: _: {
              oxlint-latest = final.callPackage ./pkgs/oxlint-latest { };
            })
          ];
        }

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users.user = import ./modules/home-manager;
            sharedModules = [ nix-index-database.homeModules.nix-index ];
          };
        }
      ];
    };
  };
}
