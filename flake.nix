{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nvf = {
      # url = "github:notashelf/nvf";
      # url = "/home/jeroen/devel/github.com/ppenguin/nvf";
      url = "github:ppenguin/nvf/improve-terraformls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          pkgs,
          self',
          system,
          ...
        }:
        {
          # https://github.com/hercules-ci/flake-parts/blob/main/template/unfree/flake.nix#L13
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate =
              pkg:
              builtins.elem (inputs.nixpkgs.lib.getName pkg) [
                "terraform"
                "nomad"
              ];
          };
          packages = {
            nvim-generic-full =
              (inputs.nvf.lib.neovimConfiguration {
                inherit pkgs;
                modules = [ ./nvfconfs/nvim-generic-full ];
              }).neovim;
            default = self'.packages.nvim-generic-full;
          };
          devShells = {
            default = pkgs.mkShell {
              buildInputs = [ self'.packages.default ];
            };
          };
        };
    };
}
