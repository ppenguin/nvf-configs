{lib, ...}: let
  inherit (lib.nvim.dag) entryAfter;
in {
  config.vim = {
    debugger.nvim-dap = {
      enable = true;
      ui = {enable = true;};
    };
    languages.enableDAP = true;
    # NOTE: doesn't work with entryAfter, because keybinds not in section...
    luaConfigPost = builtins.readFile ./lua/repeat-key.lua;
    luaConfigRC.dap-signs = entryAfter ["nvim-dap"] ''
      vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◐", texthl = "DiagnosticWarn",  linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped",             { text = "→", texthl = "DiagnosticOk",    linehl = "DapStopped", numhl = "" })
    '';
  };
}
