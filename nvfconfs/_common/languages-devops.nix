{
  lib,
  pkgs,
  ...
}: let
  complete = {
    enable = true;
    format.enable = true;
    lsp.enable = true;
    treesitter.enable = true;
  };
in {
  config.vim = {
    languages = {
      bash = complete // {extraDiagnostics.enable = true;};
      json = complete;
      nix =
        complete
        // {
          extraDiagnostics.enable = true;
          format = {
            enable = true;
            type = ["alejandra"];
          };
        };
      sql = {
        enable = true;
        format.enable = lib.mkDefault false;
        lsp.enable = true;
        treesitter.enable = true;
      };
      yaml = complete;
    };

    # nvf presets normally call these through absolute store paths. They are
    # also user-facing baseline tools, so expose them to :!, vim.system(), and
    # terminals spawned by Neovim. mnw appends this list to the inherited PATH.
    extraPackages = with pkgs; [
      alejandra
      bash-language-server
      deadnix
      jsonfmt
      nil
      nixfmt
      prettier
      shellcheck
      shfmt
      sqls
      statix
      vscode-langservers-extracted
      yaml-language-server
    ];
  };
}
