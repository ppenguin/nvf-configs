{pkgs, ...}: let
  vpkgs = pkgs.vimPlugins;
in {
  config.vim = {
    extraPlugins =
      (builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {package = vpkgs."${name}";};
        })
        [
          "nvim-jqx"
          "live-server"
          "markdown-table-mode"
        ]
      ))
      // {
        "markdown-preview-selim" = {
          package = vpkgs.markdown-preview-selim;
          setup = "require('markdown_preview').setup({ host = '0.0.0.0', port = 18421, hooks = { on_start = function(url) vim.fn.setreg('+', url); vim.fn.setreg('\"', url); vim.notify('Markdown preview (copied to clipboard): ' .. url) end } })";
        };
        nvim-dbee = {
          package = vpkgs.nvim-dbee;
          setup = "require('dbee').setup({})";
        };
      };
  };
}
