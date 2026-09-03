{
  lib,
  pkgs,
  theme ? {
    name = "tokyonight";
    style = "night";
  },
  ...
}: let
  inherit (lib.nvim.dag) entryAnywhere;
in {
  config.vim = {
    extraPackages = with pkgs; [
      fzf
      ripgrep
    ];

    theme = {
      enable = true;
      inherit (theme) name style;
      transparent = true;
    };

    globals = {
      mapleader = "\\";
      editorconfig = true;
    };

    options = {
      cursorcolumn = true;
      visualbell = true;
      wildmode = "noselect:full";
      wildoptions = "pum";
      wildmenu = true;
    };

    # Accept the first visible command-line completion when Space cancels a
    # noselect wildmenu. Command-line mappings do not fire while wildmenu owns
    # the popup, and noselect completion does not change the cmdline on Tab,
    # so the first observable state change is `:Mark `.
    luaConfigRC.optionsScript = ''
      do
        local applying_completion = false

        vim.api.nvim_create_autocmd("CmdlineChanged", {
          callback = function()
            if applying_completion or vim.fn.getcmdtype() ~= ":" then
              return
            end

            local cmdline = vim.fn.getcmdline()
            local pattern = cmdline:match("^([A-Z][%w_]*) $")
            if pattern == nil then
              return
            end

            local matches = vim.fn.getcompletion(pattern, "cmdline")
            if #matches == 0 then
              return
            end

            local completed = matches[1] .. " "
            applying_completion = true
            vim.fn.setcmdline(completed, #completed + 1)
            applying_completion = false
          end,
        })
      end
    '';

    lazy.enable = true;

    clipboard = {
      enable = true;
      # Provider binaries on PATH for the *native* (local-display) path below.
      # Neovim auto-detects wl-copy on Wayland and xclip on X11 when
      # vim.g.clipboard is left unset. Both depend on a display server, so they
      # are Linux-only (wl-clipboard/X are unavailable on Darwin).
      providers = {
        wl-copy.enable = pkgs.stdenv.hostPlatform.isLinux;
        xclip.enable = pkgs.stdenv.hostPlatform.isLinux;
      };
    };

    # Make the system clipboard behave the same in every context by picking the
    # transport at runtime rather than relying on a single provider:
    #   * local graphical session   -> native wl-copy/xclip (full copy AND paste,
    #                                   talks to the clipboard of THIS machine)
    #   * ssh / tmux / any term emu  -> OSC 52 (copy is forwarded to the terminal
    #                                   you are physically at; works through a
    #                                   remote tmux that has `set-clipboard on`)
    #   * bare Linux VT (TERM=linux) -> no transport exists (see note below)
    #
    # "local vs remote" is decided by SSH_TTY/SSH_CONNECTION, not just by the
    # presence of a display: a remote desktop host may have WAYLAND_DISPLAY/DISPLAY
    # in the env, but over ssh we still want OSC 52 so the copy reaches *your*
    # machine's clipboard rather than the remote's.
    luaConfigRC.clipboard = entryAnywhere ''
      vim.o.clipboard = "unnamedplus"

      local in_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
      local has_local_display =
        vim.env.WAYLAND_DISPLAY ~= nil or vim.env.DISPLAY ~= nil

      if (not in_ssh) and has_local_display then
        -- Local GUI session: leave vim.g.clipboard unset so Neovim auto-detects
        -- wl-copy (Wayland) / xclip (X11) for full bidirectional clipboard.
        vim.g.clipboard = nil
      elseif vim.env.TERM ~= "linux" then
        -- ssh / tmux / terminal emulator without a usable local display: OSC 52.
        local osc52 = require("vim.ui.clipboard.osc52")
        vim.g.clipboard = {
          name = "OSC 52",
          copy = {
            ["+"] = osc52.copy("+"),
            ["*"] = osc52.copy("*"),
          },
          paste = {
            ["+"] = osc52.paste("+"),
            ["*"] = osc52.paste("*"),
          },
        }
      else
        -- Bare Linux virtual console (TERM=linux): the kernel VT speaks neither
        -- OSC 52 nor a display protocol, so there is no system clipboard to reach.
        -- Yank stays in Neovim's own registers; install `gpm` for mouse-driven
        -- copy/paste *within* the console.
        vim.g.clipboard = nil
      end
    '';

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
