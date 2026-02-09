{
  pkgs,
  lib,
  ...
}: let
  enableLspOptsDefault = {
    enable = true;
    format.enable = true;
    lsp.enable = true;
    treesitter.enable = true;
  };
  inherit (lib.nvim.dag) entryAfter;
in {
  config.vim = {
    lsp = {
      enable = true; # NOTE: !important for activating the below
      formatOnSave = true;
      trouble = {
        enable = true;
      };
      lightbulb = {
        enable = true;
      };
      lspconfig.enable = true;
      lspkind.enable = true;
    };

    formatter.conform-nvim = {
      enable = true;
      # Configure prettier for markdown with custom args
    };

    languages = {
      enableFormat = true;
      bash = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      json = enableLspOptsDefault;
      lua = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      markdown = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      nix =
        enableLspOptsDefault
        // {
          extraDiagnostics.enable = true;
          format.type = ["alejandra"]; # note: removed nixfmt because it is always chosen by default
        };
      sql = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      yaml = {
        enable = true;
        lsp.enable = true;
        treesitter.enable = true;
      };
    };

    luaConfigRC.lsp-opts = entryAfter ["lsp"] (
      ''
        -- "fix" lsp popup (add border)
        local border = "single";
        local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
        function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
          opts = opts or {}
          opts.border = opts.border or border
          return orig_util_open_floating_preview(contents, syntax, opts, ...)
        end

        vim.api.nvim_create_autocmd("FileType", {
          pattern = "sh",
          callback = function()
            vim.bo.shiftwidth = 4
            vim.bo.softtabstop = 4
            vim.bo.expandtab = false
          end,
        })
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "nix",
          callback = function()
            vim.bo.shiftwidth = 2
            vim.bo.softtabstop = 2
            vim.bo.expandtab = true
          end,
        })

      ''
      + (builtins.readFile ./lua/switch-nix-fmt-conform.lua)
    );

    # needed for nixfmt switch script
    extraPackages = with pkgs; [
      alejandra
      nixfmt
    ];
  };
}
