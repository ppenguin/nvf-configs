{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.generators) mkLuaInline;
  inherit (lib.meta) getExe;

  bundledServer = {
    enable = true;
    format.enable = false;
    lsp.enable = true;
    treesitter.enable = true;
  };
in {
  config.vim = {
    lsp = {
      otter-nvim.enable = true;

      # nvf does not currently have a preset for this auxiliary server. The
      # server itself is bundled, while its linter command deliberately uses
      # the Go toolchain imported from direnv/devenv.
      servers.golangci_lint_ls = {
        enable = true;
        cmd = [(getExe pkgs.golangci-lint-langserver)];
        cmd_env.GOTOOLCHAIN = "local";
        filetypes = ["go" "gomod"];
        init_options.command = [
          "go"
          "run"
          "github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest"
          "run"
          "--output.json.path=stdout"
          "--show-stats=false"
          "--issues-exit-code=1"
        ];
        root_dir = mkLuaInline ''
          function(bufnr, on_dir)
            local function project_environment_active()
              local managed_environment = vim.env.DIRENV_DIR ~= nil
                or vim.env.DEVENV_ROOT ~= nil
              return managed_environment and vim.fn.executable("go") == 1
            end

            local function start_for_buffer()
              if not vim.api.nvim_buf_is_valid(bufnr) or not project_environment_active() then
                return
              end
              local filename = vim.api.nvim_buf_get_name(bufnr)
              local root = vim.fs.root(filename, {"go.work", "go.mod", ".git"})
              if root then on_dir(root) end
            end

            if project_environment_active() then
              start_for_buffer()
              return
            end

            -- direnv.vim imports asynchronously on VimEnter/DirChanged. Retry
            -- this buffer after it has updated vim.env.
            vim.api.nvim_create_autocmd("User", {
              pattern = "DirenvLoaded",
              once = true,
              callback = start_for_buffer,
            })
          end
        '';
      };
    };

    languages = {
      # Globally useful, lightweight exceptions.
      bash =
        bundledServer
        // {
          format.enable = true;
          extraDiagnostics.enable = true;
        };
      make = {
        enable = true;
        format.enable = true;
        extraDiagnostics.enable = true;
        treesitter.enable = true;
      };

      # Full's document workflow is global, including its formatter and linter.
      markdown =
        bundledServer
        // {
          format = {
            enable = true;
            type = ["prettier"];
          };
          extraDiagnostics.enable = true;
        };

      # Bundled language servers and parsers; project-sensitive formatters and
      # linters below resolve from the active environment.
      json = bundledServer;
      lua = bundledServer;
      nix = bundledServer;
      sql = bundledServer;
      yaml = bundledServer;
      css = bundledServer;
      go = bundledServer;
      hcl = bundledServer // {lsp.servers = ["tofu-ls"];};
      html = bundledServer;
      python = bundledServer;
      svelte = bundledServer;
      terraform = bundledServer // {lsp.servers = ["tofu-ls"];};
      typescript = bundledServer;
    };

    formatter.conform-nvim.setupOpts = {
      formatters_by_ft = {
        css = ["prettier"];
        html = ["prettier"];
        javascript = ["prettier"];
        javascriptreact = ["prettier"];
        json = ["prettier"];
        jsonc = ["prettier"];
        lua = ["stylua"];
        markdown = lib.mkForce ["markdown_prettier"];
        nix = ["alejandra"];
        sql = ["sqlfluff"];
        svelte = ["prettier"];
        typescript = ["prettier"];
        typescriptreact = ["prettier"];
        yaml = ["prettier"];
      };

      # Markdown's global preset installs Prettier. Code/config filetypes use a
      # PATH-resolved override that rejects that bundled executable. Markdown
      # uses a separately named formatter pinned to the global package.
      formatters = {
        prettier.command = lib.mkForce (mkLuaInline ''
          function(_, ctx)
            local local_bin = vim.fs.find("node_modules/.bin/prettier", {
              path = ctx.dirname,
              upward = true,
              type = "file",
            })[1]
            if local_bin then return local_bin end

            local in_project_environment = vim.env.DIRENV_DIR ~= nil
              or vim.env.DEVENV_ROOT ~= nil
            if not in_project_environment then
              return "prettier-project-environment-not-active"
            end

            local executable = vim.fn.exepath("prettier")
            local bundled = "${getExe pkgs.prettier}"
            if executable ~= "" and executable ~= bundled then return executable end
            return "prettier-not-provided-by-project"
          end
        '');
        markdown_prettier = {
          command = getExe pkgs.prettier;
          args = ["--stdin-filepath" "$FILENAME"];
        };
      };
    };

    diagnostics.nvim-lint.linters_by_ft = {
      lua = ["luacheck"];
      nix = ["statix" "deadnix"];
      sql = ["sqlfluff"];
      svelte = ["eslint_d"];
      javascript = ["eslint_d"];
      javascriptreact = ["eslint_d"];
      typescript = ["eslint_d"];
      typescriptreact = ["eslint_d"];
    };
  };
}
