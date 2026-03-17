{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nvf = {
      url = "github:notashelf/nvf"; # NOTE: don't forget to override for testing!
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      perSystem = {
        pkgs,
        self',
        system,
        ...
      }: {
        # https://github.com/hercules-ci/flake-parts/blob/main/template/unfree/flake.nix#L13
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (inputs.nixpkgs.lib.getName pkg) [
              "terraform"
              "nomad"
            ];
        };
        packages = let
          mkNvim = pkgs.lib.makeOverridable ({
            modules,
            theme ? {
              name = "tokyonight";
              style = "night";
            },
          }:
            (inputs.nvf.lib.neovimConfiguration {
              inherit pkgs;
              inherit modules;
              extraSpecialArgs = {inherit theme;};
            }).neovim);
        in {
          default = self'.packages.nvim-generic-full;
          nvim-generic-full =
            mkNvim {modules = [./nvfconfs/nvim-generic-full];};
          nvim-lean-devops =
            mkNvim {modules = [./nvfconfs/nvim-lean-devops];};
        };
        devShells = {
          default = pkgs.mkShell {
            buildInputs = [self'.packages.default];
          };
        };
      };
    };
}
