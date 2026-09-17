# Improvement implementation record

Reviewed and implemented on 2026-09-17 against the goals in `AGENTS.md`.
The items from the original review are complete. Decisions to retain an existing
integration are recorded here because they were evaluated as part of the work;
they are not outstanding tasks.

## Result

- SOPS editing no longer risks truncating the encrypted source on a failed save.
- Profiles are composed from reusable editing, workflow, language, debugging,
  and full-extras groups.
- The devops profile now has an explicit, PATH-exposed Nix/shell/YAML/JSON/SQL
  baseline, with SQL formatting omitted after measuring its cost.
- Full inherits that complete baseline, then adds full-only language, formatting,
  diagnostics, DAP, and document capabilities.
- Go linting uses `golangci-lint-langserver` with the project-selected Go
  toolchain and the intentional v2 `@latest` command.
- The confirmed keymap, file-copy, autopair, DAP-repeat, document-placement,
  indentation, and macOS clipboard issues are fixed.
- Both wrapped editors have package and startup checks in the flake.

## Data-safety fixes

### SOPS editing

`nvfconfs/_common/lua/sops_edit.lua` now decrypts into an in-memory `acwrite`
buffer with swap and persistent undo disabled. Decryption failures leave the
buffer and source untouched. On `:write`, plaintext is sent to the bundled SOPS
process over stdin; encrypted output is written to a mode-preserving secure
sibling temporary file, flushed, and atomically renamed over the original only
after encryption succeeds.

Autocommands use a unique buffer-local group, so editing another SOPS file no
longer clears the first file's save hook. Errors are reported in Neovim and a
failed encryption or replacement keeps both the encrypted source and modified
plaintext buffer available for recovery.

This workflow was committed separately as `d4f762e` so it can be reverted
without reverting the profile refactor. Disposable fake-SOPS tests covered
concurrent edited buffers, successful decrypt/save, and encryption failure; each
buffer kept its own save hook and the failure case preserved the original
encrypted bytes and modified buffer state. No real secret material was used.
The save command uses SOPS's `encrypt` subcommand, whose stdin mode works with
`--filename-override`; the legacy `--encrypt` flag requires a positional file and
otherwise fails with `Error: no file specified`.

### nvim-tree multi-copy

`nvimtree-cp-multi.lua` now splits the clipboard only at line boundaries, so
spaces in paths are preserved. It validates the source and destination, invokes
`cp` with an argument vector, checks every result, reports failures, and asks
whether to overwrite/merge, skip, or cancel when a destination already exists.
A headless fixture copied `file with spaces.txt` into a target directory and
confirmed that the tree reload callback ran.

## Profile architecture

The duplicated profile import lists were replaced by these entry points:

- `_groups/editing-core.nix`
- `_groups/workflow-core.nix`
- `_groups/languages-devops.nix`
- `_groups/languages-full.nix`
- `_groups/debug-full.nix`
- `_groups/extras-full.nix`

`_common/lsp.nix` now owns only the shared LSP, Conform, nvim-lint, indentation,
and Nix-formatter-switch framework. Devops language packages live in
`_common/languages-devops.nix`; `_groups/languages-full.nix` imports that entire
baseline before `nvim-generic-full/lsp.nix` adds full-specific capabilities.
This makes the full language profile a literal augmentation of devops.

### Devops baseline

The lean profile enables Nix, shell, YAML, JSON, and SQL with bundled LSP and
Treesitter support. Nix, shell, YAML, and JSON also retain bundled formatting and
applicable diagnostics. Every intentional baseline executable is included in
`vim.extraPackages`, making commands such as Alejandra, nixfmt, Statix, Deadnix,
ShellCheck, shfmt, jsonfmt, and the language servers available through `:!`,
`vim.system()`, and Neovim terminals.

SQL keeps syntax support and SQLS but does not include SQLFluff formatting or
linting. Removing SQLFluff reduced the current devops runtime closure from
919.0 MiB to 703.8 MiB. Lua and Markdown language tooling remain outside this
profile. SOPS and the familiar shared editor/UI capability set remain bundled.

Sqruff was tested as a possible lean SQL formatter. With the pinned nixpkgs it
introduced 427 derivations, including an uncached Rust/bootstrap chain, and the
offline build could not obtain a required bootstrap source. Neither formatter
is a good fit for ad hoc server use, so SQL formatting is a full-only
augmentation and continues to use the supported SQLFluff integration there.

### Full language policy

The full profile inherits all devops language settings, packages, and PATH
entries, then adds nvf-provided language servers and parsers for its broader
language set. It adds SQLFluff formatting/diagnostics back as an always-available
full capability. Full-only bundled services and adapters are likewise added to
`vim.extraPackages`, so their commands are available to `:!`, `vim.system()`,
and Neovim terminals. Go and Python DAP adapters remain bundled: the measured
variant without those language adapters saved only about 120 MiB from the
earlier roughly 4.0 GiB closure and did not demonstrate equivalent nvf
configuration and usage DX.

Project-sensitive tools are configured in the editor but resolved from the
active environment:

| Additional full role | Environment-provided command |
| --- | --- |
| Web formatting | `prettier`, preferring `node_modules/.bin/prettier` |
| Lua formatting/diagnostics | `stylua`, `luacheck` |
| JS/TS/Svelte diagnostics | `eslint_d` |

The shared nvim-lint runner checks command availability and skips unavailable
project tools quietly. Markdown uses a separately named formatter pinned to the
bundled Prettier, preventing global Prettier from becoming a fallback for web
filetypes. Nix, shell, YAML, and JSON come from the inherited baseline; SQLFluff,
Markdown, and GNU Make are full augmentations or exceptions.

A clean-environment runtime check confirmed that Markdown's bundled formatter is
available while the project Prettier formatter is unavailable. A disposable
project with `node_modules/.bin/prettier` confirmed that the local executable is
selected even outside a managed environment.

### Go diagnostics

The full profile bundles the small `golangci-lint-langserver` executable as an
auxiliary Go LSP. It activates only when direnv/devenv is active, `go` is on
`PATH`, and the buffer belongs to a Go module/workspace or Git root. It also
retries after direnv.vim emits `DirenvLoaded`.

The server runs:

```text
go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest run \
  --output.json.path=stdout --show-stats=false --issues-exit-code=1
```

`GOTOOLCHAIN=local` prevents automatic toolchain substitution. The former Go
nvim-lint job was removed, while nvim-lint remains for other languages. Runtime
inspection confirmed the v2 command, local-toolchain environment, and absence of
a Go nvim-lint binding.

## Correctness and behavior fixes

- Visual `<leader>js` and `<leader>je` mappings now use a range-aware visual Ex
  filter, so jq receives and replaces the selection.
- `nvim-autopairs` is the sole shared pair engine; `mini.pairs` is disabled.
- The DAP `,` repeat mapping is installed after session initialization and
  removed after termination, exit, or disconnect, restoring Vim's native reverse
  `f`/`t` repeat outside debugging.
- Lazygit remains in the shared workflow and Neogit remains an additional full
  interface, as both are intentionally used.
- `md2pdf` mappings moved to the full document group. The optional command still
  resolves from project environments and is not bundled.
- Full retains its global Markdown preview, Mermaid, image, and document workflow.
- Local macOS sessions now use Neovim's native clipboard provider detection.
- `.editorconfig` specifies two-space indentation for Nix, matching Neovim.
- Shared modules reuse the injected `mkKeymapD`; unused imports, empty settings,
  and stale disabled experiments were removed.
- Custom Markdown plugin forks remain pinned and their upstream PRs and rollback
  revisions are documented in the overlay and README.

## Dependency measurements

Measurements use `nix path-info -Sh` on the realized x86_64-linux wrappers.
They include runtime closure references and are therefore evidence for profile
placement rather than package-size claims in isolation.

| Profile | Before | After | Change |
| --- | ---: | ---: | ---: |
| `nvim-generic-full` | about 4.0 GiB | about 3.5 GiB | about -0.5 GiB |
| `nvim-lean-devops` | about 1.2 GiB | 703.8 MiB | about -0.5 GiB |

The full reduction mainly comes from externalizing project-sensitive tools
outside the inherited baseline. Its intentional Markdown browser/rendering and
full-only SQLFluff closures remain. The devops reduction comes from removing
Markdown/.NET/Deno and Lua tooling, followed by moving SQLFluff to full.

## Automated and manual validation

- Both profiles evaluate on `x86_64-linux`, `aarch64-linux`, and
  `aarch64-darwin`.
- Both x86_64-linux wrappers build successfully.
- `checks.<system>` includes both packages and a headless startup smoke test.
- The smoke test checks SOPS availability, full-only document mappings,
  inherited baseline commands, full-only bundled commands and SQLFluff, DAP
  comma scope, and the Go toolchain setting.
- Headless runtime checks covered project-local versus bundled Prettier,
  Markdown formatting invocation, absence of duplicate Go linting, visual jq
  mapping form, nvim-tree space-containing paths, DAP mapping lifecycle, and
  nvim-autopairs ownership after `InsertEnter`.
- Closure differences were inspected with `nix-store -qR`, `nix path-info`, and
  `nix why-depends` while classifying removed tools.

Cross-platform validation is evaluation-only; non-host packages were not built.
Interactive tmux and macOS sessions, a real DAP target, and real SOPS keys still
need ordinary daily-driver exercise. Headless full-profile startup emits the
expected image.nvim terminal-size notice because no terminal is attached.
