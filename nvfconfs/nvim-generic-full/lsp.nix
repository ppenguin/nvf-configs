let
  enableLspOptsDefault = {
    enable = true;
    format.enable = true;
    lsp.enable = true;
    treesitter.enable = true;
  };
in {
  config.vim = {
    lsp = {
      enable = true; # NOTE: !important for activating the below
      formatOnSave = true;
      trouble = {enable = true;};
      otter-nvim = {enable = true;};
      lightbulb = {enable = true;};
      lspconfig.enable = true;
      lspkind.enable = true;
    };

    formatter.conform-nvim.enable = true;

    languages = {
      enableFormat = true;
      bash = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      css = enableLspOptsDefault;
      go = enableLspOptsDefault; # TODO: add dap config
      hcl = enableLspOptsDefault // {lsp.servers = ["tofuls"];};
      html = enableLspOptsDefault;
      json = enableLspOptsDefault;
      lua = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      markdown = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      nix = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      python = enableLspOptsDefault;
      sql = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      svelte = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      terraform = {
        enable = true;
        lsp = {
          enable = true;
          servers = ["tofuls"];
        };
        treesitter.enable = true;
      };
      ts = enableLspOptsDefault // {extraDiagnostics.enable = true;};
      yaml = {
        enable = true;
        lsp.enable = true;
        treesitter.enable = true;
      };
    };
  };
}
