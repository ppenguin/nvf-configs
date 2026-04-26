{pkgs, ...}: let
  vpkgs = pkgs.vimPlugins;
in {
  config.vim = {
    # here we can provide custom setup
    extraPlugins =
      (builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {package = vpkgs."${name}";};
        })
        [
          "nvim-jqx"
          "markdown-preview-selim" # NOTE: needs overlay
          "live-server" # NOTE: dep of markdown-preview-selim, needs overlay
          "markdown-table-mode"
        ]
      ))
      // {
        nvim-dbee = {
          package = vpkgs.nvim-dbee;
          setup = "require('dbee').setup({})";
        };
      };
  };
}
