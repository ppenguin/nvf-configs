{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nvf = {
      url = "github:notashelf/nvf"; # NOTE: don't forget to override for testing!
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      perSystem = {
        pkgs,
        self',
        system,
        ...
      }: {
        # https://github.com/hercules-ci/flake-parts/blob/main/template/unfree/flake.nix#L13
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (inputs.nixpkgs.lib.getName pkg) [
              "terraform"
              "nomad"
              "barbar.nvim"
            ];
          overlays = [
            (import ./overlays/vim-plugins.nix)
          ];
        };
        packages = let
          mkNvim = pkgs.lib.makeOverridable ({
            modules,
            theme ? {
              name = "tokyonight";
              style = "night";
            },
          }:
            (inputs.nvf.lib.neovimConfiguration {
              inherit pkgs;
              inherit modules;
              extraSpecialArgs = {inherit theme;};
            }).neovim);
        in {
          default = self'.packages.nvim-generic-full;
          nvim-generic-full =
            mkNvim {modules = [./nvfconfs/nvim-generic-full];};
          nvim-lean-devops =
            mkNvim {modules = [./nvfconfs/nvim-lean-devops];};
        };
        devShells = {
          default = pkgs.mkShell {
            buildInputs = [self'.packages.default];
          };
        };

        checks = {
          inherit (self'.packages) nvim-generic-full nvim-lean-devops;

          startup-smoke = pkgs.runCommand "nvf-startup-smoke" {} ''
            export HOME="$TMPDIR/home"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            export XDG_STATE_HOME="$TMPDIR/state"
            export TERM=dumb
            mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

            ${self'.packages.nvim-generic-full}/bin/nvim --headless \
              "+lua local conform = require('conform'); local lint = require('lint'); local baseline = {'alejandra', 'bash-language-server', 'deadnix', 'fd', 'jsonfmt', 'lazygit', 'nil', 'nixfmt', 'prettier', 'shellcheck', 'shfmt', 'sqls', 'statix', 'vscode-json-language-server', 'yaml-language-server'}; local additions = {'basedpyright-langserver', 'checkmake', 'debugpy', 'debugpy-adapter', 'dlv', 'golangci-lint-langserver', 'gopls', 'lua-language-server', 'marksman', 'markdownlint-cli2', 'mbake', 'sqlfluff', 'superhtml', 'svelteserver', 'tofu-ls', 'typescript-language-server'}; for _, command in ipairs(baseline) do assert(vim.fn.executable(command) == 1, command) end; for _, command in ipairs(additions) do assert(vim.fn.executable(command) == 1, command) end; assert(vim.fn.exists(':SopsEdit') == 2); assert(#vim.fn.maparg('<leader>mp', 'n') > 0); assert(#vim.fn.maparg(',', 'n') == 0); assert(vim.fn.maparg('<leader>js', 'x'):sub(1, 4) == ':!jq'); assert(lint.linters_by_ft.go == nil); assert(lint.linters_by_ft.sql[1] == 'sqlfluff'); assert(conform.formatters_by_ft.sql[1] == 'sqlfluff'); assert(conform.get_formatter_info('markdown_prettier', 0).available); assert(conform.get_formatter_info('prettier', 0).available); assert(not conform.get_formatter_info('project_prettier', 0).available); assert(vim.lsp.config.golangci_lint_ls.cmd_env.GOTOOLCHAIN == 'local')" \
              +qa!

            ${self'.packages.nvim-lean-devops}/bin/nvim --headless \
              "+lua local conform = require('conform'); local baseline = {'alejandra', 'bash-language-server', 'deadnix', 'fd', 'jsonfmt', 'lazygit', 'nil', 'nixfmt', 'prettier', 'shellcheck', 'shfmt', 'sqls', 'statix', 'vscode-json-language-server', 'yaml-language-server'}; for _, command in ipairs(baseline) do assert(vim.fn.executable(command) == 1, command) end; assert(vim.fn.exists(':SopsEdit') == 2); assert(#vim.fn.maparg('<leader>mp', 'n') == 0); assert(vim.fn.executable('marksman') == 0); assert(conform.get_formatter_info('alejandra', 0).available); assert(conform.formatters_by_ft.sql == nil); assert(require('lint').linters_by_ft.sql == nil); assert(vim.fn.executable('sqlfluff') == 0)" \
              +qa!

            touch "$out"
          '';
        };
      };
    };
}
