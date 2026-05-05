{
  lib,
  pkgs,
  theme ? {
    name = "tokyonight";
    style = "night";
  },
  ...
}: {
  config.vim = {
    extraPackages = with pkgs; [
      fzf
      ripgrep
    ];

    theme = {
      enable = true;
      inherit (theme) name style;
    };

    globals = {
      mapleader = "\\";
      editorconfig = true;
    };

    options = {
      cursorcolumn = true;
      visualbell = true;
      wildmode = "full";
      wildmenu = true;
    };

    # "fix" selection behaviour of commandline suggestions
    luaConfigRC.optionsScript = ''
      vim.keymap.set('c', '<Space>', function()
        if vim.fn.pumvisible() == 1 then
          return '<C-y> '  -- confirm + space
        end
        return ' '
      end, { expr = true })
    '';

    lazy.enable = true;

    clipboard = {
      enable = true;
      providers = {
        # wl-clipboard depends on wayland, which is unavailable on Darwin
        wl-copy.enable = pkgs.stdenv.isLinux;
      };
    };

    autocomplete = {
      nvim-cmp.enable = false;
      blink-cmp = {
        enable = true;
        mappings = {
          confirm = "<S-return>";
        };
        sourcePlugins.emoji.enable = true;
      };
    };

    autopairs.nvim-autopairs.enable = true;

    binds = {
      cheatsheet.enable = true;
      whichKey.enable = true; # (try mini.clue -> didn't work)
    };

    treesitter = {
      enable = true;
      # textobjects.enable = true; # FIXME: doesn't work, prolly missing dep?
      context.enable = true;
    };

    telescope = {
      enable = true;
    };

    notes = {
      todo-comments = {
        enable = true;
      };
    };

    comments.comment-nvim.enable = true; # has good defaults?

    git = {
      enable = true;
      gitsigns.enable = true;
      vim-fugitive.enable = true;
    };
  };
}
