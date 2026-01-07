{pkgs, ...}: {
  config.vim = {
    extraPackages = with pkgs; [
      fzf
      ripgrep
      imagemagick # for image preview conversions
      mermaid-cli
    ];

    theme = {
      enable = true;
      name = "tokyonight";
      style = "night";
    };

    globals = {
      mapleader = "\\";
      editorconfig = true;
    };

    options = {
      cursorcolumn = true;
      visualbell = true;
    };

    lazy.enable = true;

    clipboard = {
      enable = true;
      providers = {
        wl-copy.enable = true;
      };
    };

    autocomplete = {
      nvim-cmp.enable = false;
      blink-cmp.enable = true;
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
      neogit.enable = true; # TODO: decide whether this stays and test it // replace lazygit?!
    };
  };
}
