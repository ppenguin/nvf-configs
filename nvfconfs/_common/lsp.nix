{lib, ...}: let
  inherit (lib.generators) mkLuaInline;
  inherit (lib.nvim.dag) entryAfter;
in {
  config.vim = {
    lsp = {
      enable = true;
      formatOnSave = true;
      trouble.enable = true;
      lightbulb.enable = true;
      lspconfig.enable = true;
      lspkind.enable = true;
    };

    diagnostics.nvim-lint = {
      enable = true;

      # nvf's default runner assumes every configured command exists. Full uses
      # PATH-resolved project linters, so unavailable tools must be skipped
      # quietly outside a development environment.
      lint_function = mkLuaInline ''
        function(buf)
          local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
          local lint = require("lint")
          local configured = lint.linters_by_ft[ft]
          if configured == nil then return end

          for _, name in ipairs(configured) do
            local linter = lint.linters[name]
            assert(linter, "Linter with name `" .. name .. "` not available")
            if type(linter) == "function" then linter = linter() end
            linter.name = linter.name or name

            local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
            local executable = type(cmd) == "table" and cmd[1] or cmd
            local available = type(executable) ~= "string"
              or executable:find("/", 1, true) ~= nil and vim.uv.fs_stat(executable) ~= nil
              or vim.fn.executable(executable) == 1

            if available then
              local required_files = linter.required_files
              if required_files == nil then
                lint.try_lint(name)
              else
                local cwd = linter.cwd or vim.fn.getcwd()
                for _, filename in ipairs(required_files) do
                  if vim.uv.fs_stat(vim.fs.joinpath(cwd, filename)) then
                    lint.try_lint(name)
                    break
                  end
                end
              end
            end
          end
        end
      '';
    };

    formatter.conform-nvim.enable = true;

    luaConfigRC.lsp-opts = entryAfter ["lsp"] (
      ''
        local border = "single"
        local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
        function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
          opts = opts or {}
          opts.border = opts.border or border
          return orig_util_open_floating_preview(contents, syntax, opts, ...)
        end

        vim.api.nvim_create_autocmd("FileType", {
          pattern = {"sh", "go", "make"},
          callback = function()
            vim.bo.shiftwidth = 4
            vim.bo.tabstop = 4
            vim.bo.softtabstop = 0
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
  };
}
