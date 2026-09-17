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
      indent-blankline.enable = true; # will this fix the crappy behaviour for nix files and o
    };

    dashboard = {
      startify.enable = false;
      dashboard-nvim.enable = false;
      alpha.enable = true;
    };

    statusline.lualine = {
      enable = true;
      # 2026-09-11: nvf removed `activeSection.<x>`; the replacement is
      # `setupOpts.sections.lualine_<x>`, and it takes a Nix list of attrsets
      # rather than a raw Lua string (positional lualine args use the "@1" key,
      # raw Lua would need {_type = "lua-inline"; expr = ...;}).
      # This is nvf's own default for lualine_b with our one deviation kept:
      # path = 1 on `filename`, so we get the full path.
      setupOpts.sections.lualine_b = [
        {
          "@1" = "filetype";
          colored = true;
          icon_only = true;
          icon.align = "left";
        }
        {
          "@1" = "filename";
          path = 1; # the only change from the nvf default
          symbols = {
            modified = " ";
            readonly = " ";
          };
          separator.right = "";
        }
        {
          "@1" = "";
          draw_empty = true;
          separator = {
            left = "";
            right = "";
          };
        }
      ];
    };

    ui = {
      colorizer = {
        enable = true;
        setupOpts = {
        filetypes."*" = {};
        user_default_options = {
            names = true;
            RRGGBB = true;
            RRGGBBAA = true;
            css = true;
            css_fn = true;
            hsl_fn = true;
            rgb_fn = true;
            # sass = true;
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
