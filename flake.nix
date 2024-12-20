{
  description = "nvim-thyme: ZERO overhead Fennel runtime compiler for neovim config";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };
  outputs = {
    nixpkgs,
    systems,
    ...
  }: let
    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (system:
        f {
          pkgs = nixpkgs.legacyPackages.${system};
        });
  in {
    devShells = eachSystem ({pkgs, ...}: {
      default = pkgs.mkShellNoCC {
        name = "nvim-thyme";
        packages = with pkgs; [
          luajit
          fennel
        ];
      };
    });
  };
}
