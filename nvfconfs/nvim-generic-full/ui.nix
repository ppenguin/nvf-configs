{
  config.vim = {
    highlight = {
      # vim.cmd[[highlight WinSeparator guifg=#aaaaaa]]
      WinSeparator = {
        fg = "#aaaaaa";
      };
    };

    visuals = {
      # nvim-cursorline.enable = true;
      nvim-web-devicons.enable = true; # needed for trouble (and probably others)
      rainbow-delimiters.enable = true;
      fidget-nvim = {
        enable = true;
        setupOpts = {notification.override_vim_notify = true;};
      };
    };

    dashboard = {
      startify.enable = false;
      dashboard-nvim.enable = false;
      alpha.enable = true;
    };

    statusline.lualine = {
      enable = true;
      activeSection.b = [(builtins.readFile ./lua/lualine.b.lua)];
    };

    # NOTE: use mini-map from mini instead
    # minimap = {
    #   minimap-vim.enable = true;
    #   codewindow.enable = false; # FIXME: throws error ts_utils not found (bug) => is probably enabled by other option
    # };

    projects = {
      project-nvim = {
        enable = true;
        setupOpts = {manual_mode = false;};
      };
    };

    # notify.nvim-notify.enable = true; # TODO: check if fidget adequately replaces this

    ui = {
      colorizer = {
        enable = true;
        setupOpts.filetypes = {
          d2 = {
            RRGGBB = true;
            names = true;
          };
          html = {
            RRGGBB = true;
            RRGGBBAA = true;
          };
          markdown = {
            RRGGBB = true;
            RRGGBBAA = true;
          };
          css = {
            css = true;
            css_fn = true;
          };
          sass = {
            css = true;
            css_fn = true;
            sass = true;
          };
          javascript = {
            RRGGBB = true;
            RRGGBBAA = true;
          };
          go = {
            RRGGBB = true;
          };
        };
      };

      # modes-nvim.setupOpts = {
      #   setCursorline = true;
      #   line_opacity.visual = 0.3;
      # };
      smartcolumn.enable = true;
    };
  };
}
