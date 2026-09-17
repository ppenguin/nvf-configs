# nvf-configs

Two composable [nvf](https://github.com/NotAShelf/nvf) Neovim profiles for a
full daily driver and ad hoc editing on headless machines.

## Run a profile

Run the lean profile directly on a server:

```console
nix run github:ppenguin/nvf-configs#nvim-lean-devops
```

Run the full profile, which is also the flake's default package:

```console
nix run github:ppenguin/nvf-configs#nvim-generic-full
# equivalent:
nix run github:ppenguin/nvf-configs
```

The default development shell contains the full editor:

```console
nix develop
```

## Profiles

| Capability | `nvim-lean-devops` | `nvim-generic-full` |
| --- | --- | --- |
| Shared editing, navigation, file tree, terminal and Git UI | yes | yes |
| SOPS editing | bundled | bundled |
| Languages | Nix, shell, YAML, JSON, SQL | broad daily-driver set |
| Baseline language tools | bundled and on `PATH` | inherited from devops and on `PATH` |
| Additional project-sensitive tools | no | resolved from direnv/devenv |
| Markdown preview, Mermaid, images and document mappings | no | bundled/global |
| Debugging | no | nvf DAP integrations |
| Git interfaces | lazygit | lazygit and Neogit |

The profiles are composed from modules in `nvfconfs/_groups`. Full's language
group imports the complete devops baseline and then augments it; shared editing
and workflow behavior remains independently reusable by other variants.

## Home Manager

Add the flake as an input and install its wrapped package:

```nix
{
  inputs.nvf-config.url = "github:ppenguin/nvf-configs";

  outputs = inputs@{ nvf-config, ... }: {
    # Pass `inputs` to the Home Manager module in the usual way.
  };
}
```

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.nvf-config.packages.${pkgs.system}.nvim-generic-full
  ];
}
```

Pin the input through the consuming system's lock file. Updating that input
updates the daily-driver editor.

## Tool placement

The lean profile bundles completion and editing support for Nix, shell, YAML,
JSON, and SQL. Nix, shell, YAML, and JSON include their formatter and diagnostic
tools. SQL includes Treesitter and SQLS; SQLFluff is omitted because its Python
closure is significant for ad hoc remote use.

Every baseline language executable is also added to nvf's `extraPackages`, so
commands such as `alejandra`, `nixfmt`, `statix`, `deadnix`, `shfmt`, `jsonfmt`,
and the bundled language servers work through `:!`, `vim.system()`, and Neovim
terminals. nvf appends them to the inherited `PATH`.

The full profile inherits that complete baseline, adds SQLFluff as a full-only
formatter/linter, and bundles its additional language servers and nvf debug
adapters. Those additional bundled commands—including `gopls`, `dlv`,
`marksman`, `lua-language-server`, `basedpyright-langserver`, `debugpy`, and
`tofu-ls`—are also on the appended Neovim `PATH`. Additional project-sensitive
commands use direnv/devenv:

- Prettier for web filetypes, with a project-local
  `node_modules/.bin/prettier` preferred;
- Stylua for Lua;
- `eslint_d` for JavaScript, TypeScript and Svelte diagnostics.

Missing additional project tools are skipped quietly outside a development
environment. Markdown is deliberately global and uses bundled Prettier. The
inherited Nix/shell/YAML/JSON baseline, full-only SQLFluff, and GNU Make support
are also always available.

Go diagnostics use the bundled `golangci-lint-langserver`, but only start in a
direnv/devenv Go project. The server invokes:

```console
go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest run \
  --output.json.path=stdout --show-stats=false --issues-exit-code=1
```

`GOTOOLCHAIN=local` keeps the invocation on the project-selected Go toolchain.
There is no second Go `nvim-lint` job.

## Shared workflows

Open an encrypted SOPS file and press `<leader>so` (or run `:SopsEdit`). The
buffer is decrypted in memory with swap and persistent undo disabled. `:write`
encrypts into a secure sibling temporary file and atomically replaces the
original only after SOPS succeeds.

The full profile provides Markdown preview with Mermaid and image support.
`<leader>mp`, `<leader>mpo`, and `<leader>mpu` invoke `md2pdf`; that optional
command comes from project-specific Pandoc environments and is intentionally not
bundled here.

`nvim-autopairs` is the shared pairing engine. `mini.pairs` is disabled while
the other selected Mini modules remain enabled. During an active DAP session,
`,` repeats the last wrapped DAP action; when the session ends, Vim's native
reverse `f`/`t` repeat is restored.

## Custom plugins

`overlays/vim-plugins.nix` pins the custom plugins used by the full Markdown
workflow. `markdown-preview-selim` and `live-server` temporarily use forks that
carry the changes proposed in upstream
[markdown-preview.nvim PR 28](https://github.com/selimacerbas/markdown-preview.nvim/pull/28)
and [live-server.nvim PR 5](https://github.com/selimacerbas/live-server.nvim/pull/5).
The original revisions remain documented next to the overrides for easy review
when either fork is updated or the upstream fixes land.

## Platforms and validation

Linux is the primary target, including SSH/tmux use. The flake also evaluates
both profiles for `aarch64-darwin`; macOS receives low-cost compatibility such
as native clipboard detection.

Useful checks while changing the configuration:

```console
nix flake check --offline
nix build --offline .#nvim-generic-full .#nvim-lean-devops
nix eval --offline --raw .#packages.aarch64-darwin.nvim-generic-full.drvPath
```

The flake check builds both current-system profiles and runs both wrappers
headlessly to catch startup and profile-placement regressions. See
`AGENTS.md` for the agreed design policy and `IMPROVEMENTS.md` for the completed
review record and measurements.
