{
  description = "nvim-thyme: ZERO overhead Fennel runtime compiler for neovim config";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    fennel-ls.url = "git+https://git.sr.ht/~xerool/fennel-ls";
    fennel-ls.flake = false;
  };
  outputs = inputs @ {
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
        buildInputs = with pkgs; [
          gnumake
          cargo # for parinfer-rust integration tests
          lua51Packages.fennel
          (fennel-ls.overrideAttrs (prevAttrs: {
            src = inputs.fennel-ls;
            buildInputs =
              prevAttrs.buildInputs
              ++ [
                pandoc
              ];
          }))

          luajitPackages.vusted
        ];
      };
    });
    formatter = eachSystem ({pkgs, ...}:
      inputs.treefmt-nix.lib.mkWrapper pkgs {
        projectRootFile = "flake.nix";
        programs = {
          actionlint.enable = true;
          alejandra.enable = true;
          # fnlfmt.enable = true; # https://todo.sr.ht/~technomancy/fennel/242
          shfmt.enable = true;
        };
        settings.formatter = {
          shfmt.includes = [".githooks/*"];
        };
      });
  };
}
