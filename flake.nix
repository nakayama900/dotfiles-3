{
  #ref: https://github.com/yasunori0418/dotfiles/blob/485eee2794c2e5217823b7bba5201e9f9fe16d1e/flake.nix#L2
  description = "My dotfiles, all my effort, my sword.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay-tarball.url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      treefmt-nix,
      catppuccin,
      neovim-nightly-overlay,
      emacs-overlay,
      emacs-overlay-tarball
    }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      overlays = [
        neovim-nightly-overlay.overlays.default
	(import (builtins.fetchTarball {
	  url = emacs-overlay-tarball.url;
	}))
      ];
    in
    # code = _: s: s;
    {
      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      checks.x86_64-linux = {
        format = treefmtEval.config.build.wrapper;
      };

      nixosConfigurations = {
        NixOS = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            inputs.catppuccin.nixosModules.catppuccin
          ];
          specialArgs = {
            inherit inputs;
          };
          # inputs.catppuccin.enable = true;
        };
      };
      homeConfigurations = {
        Home = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home.nix
            inputs.catppuccin.homeManagerModules.catppuccin
            {
              nixpkgs.overlays = overlays;
            }
          ];
        };
      };

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          lua-language-server
          stylua
          nil
        ];

        inputsFrom =
          [
          ];

        # shellHook = ''
        #   export DEBUG=1
        # '';
      };
    };
}
