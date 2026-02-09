let
  enableLspOptsDefault = {
    enable = true;
    format.enable = true;
    lsp.enable = true;
    treesitter.enable = true;
  };
  # inherit (lib.nvim.dag) entryAfter;
in {
  config.vim = {
    lsp = {
      # only additional to ../_common/lsp.nix
      otter-nvim = {
        enable = true;
      };
    };

    formatter.conform-nvim = {
      # Configure prettier for markdown with custom args
      setupOpts = {
        formatters_by_ft = {
          markdown = ["prettier"];
        };

        formatters = {
          prettier = {
            prepend_args = [
              "--prose-wrap"
              "preserve"
              "--print-width"
              "999" # Prevents wrapping tables
            ];
          };
        };
      };
    };

    languages = {
      enableFormat = true;
      css = enableLspOptsDefault;
      go = enableLspOptsDefault; # TODO: add dap config
      hcl = enableLspOptsDefault // {lsp.servers = ["tofuls-hcl"];};
      html = enableLspOptsDefault;
      python = enableLspOptsDefault;
      svelte = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      terraform = {
        enable = true;
        lsp = {
          enable = true;
          servers = ["tofuls-tf"];
        };
        treesitter.enable = true;
      };
      ts = enableLspOptsDefault // {extraDiagnostics.enable = true;};
    };
  };
}
