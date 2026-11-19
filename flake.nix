{
  description = "meitetu dotfiles — NixOS + Home Manager (Akari theme, zsh, nvim)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Face authentication (nixpkgs has no `gaze` package)
    gaze = {
      url = "github:GunduLabs/gaze";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, gaze, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      # Common arguments every module gets.
      specialArgs = { inherit inputs system; };
    in {
      # ----------------------------------------------------------------------
      # NixOS hosts
      # ----------------------------------------------------------------------
      nixosConfigurations = {
        akari = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            ./hosts/akari
            ./modules/akari
            gaze.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.sharedModules = [
                ./modules/akari/home.nix
                ./modules/zsh
                ./modules/nvim
                ./modules/starship
              ];
              home-manager.users.meitetu = import ./hosts/akari/home.nix;
            }
          ];
        };
      };

      # ----------------------------------------------------------------------
      # Standalone Home Manager (non-NixOS or testing)
      # ----------------------------------------------------------------------
      homeConfigurations."meitetu" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = specialArgs;
        modules = [
          ./modules/akari/home.nix
          ./modules/zsh
          ./modules/nvim
          ./modules/starship
          ./hosts/akari/home.nix
        ];
      };

      # ----------------------------------------------------------------------
      # Modules for reuse
      # ----------------------------------------------------------------------
      nixosModules = {
        akari = ./modules/akari;
      };

      homeModules = {
        akari = ./modules/akari/home.nix;
        zsh = ./modules/zsh;
        nvim = ./modules/nvim;
        starship = ./modules/starship;
      };

      # ----------------------------------------------------------------------
      # Formatter
      # ----------------------------------------------------------------------
      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
