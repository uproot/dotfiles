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

    # Quickshell — pinned to the rev that end-4/dots-hyprland tests against
    # (`sdata/dist-nix/home-manager/flake.nix`).  Bump deliberately when you
    # also bump the vendored ./modules/home-manager/wayland/quickshell/ii.
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell?rev=7511545ee20664e3b8b8d3322c0ffe7567c56f7a";
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
