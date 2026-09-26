{pkgs, ...}: let
  vpkgs = pkgs.vimPlugins;
in {
  config = {
    vim = {
      # here we can provide custom setup
      extraPlugins =
        (builtins.listToAttrs (
          map (name: {
            inherit name;
            value = {package = vpkgs."${name}";};
          })
          [
            "nvim-jqx"
            "live-server" # NOTE: dep of markdown-preview-selim, needs overlay
            "markdown-table-mode"
          ]
        ))
        // {
          "markdown-preview-selim" = {
            package = vpkgs.markdown-preview-selim; # NOTE: needs overlay
            setup = "require('markdown_preview').setup({ host = '0.0.0.0', port = 18421, hooks = { on_start = function(url) vim.fn.setreg('+', url); vim.fn.setreg('\"', url); vim.notify('Markdown preview (copied to clipboard): ' .. url) end } })";
          };
          nvim-dbee = {
            package = vpkgs.nvim-dbee;
            setup = "require('dbee').setup({})";
          };
          silverbullet-nvim = {
            package = vpkgs.silverbullet-nvim; # NOTE: needs overlay
            # env-driven spaces/token + query results, see ./lua/silverbullet-nvim
            setup = "require('silverbullet-nvim.setup').setup()";
          };
        };

      # makes ./lua/silverbullet-nvim/*.lua require-able as `silverbullet-nvim.<name>`
      additionalRuntimePaths = [
        (pkgs.linkFarm "silverbullet-nvim-config" [
          {
            name = "lua/silverbullet-nvim";
            path = ./lua/silverbullet-nvim;
          }
        ])
      ];

      extraPackages = [pkgs.curl]; # NOTE: silverbullet-nvim transport

      autocomplete.blink-cmp.setupOpts.sources = {
        default = ["silverbullet"];
        providers.silverbullet = {
          name = "silverbullet";
          module = "silverbullet.blink_source";
        };
      };
    };
  };
}
