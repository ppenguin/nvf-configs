# Repository goals and working guidance

This document records the goals agreed with the owner and guidance for future
work. The current profiles implement the architecture and tool-placement policy
below; preserve those decisions unless new evidence or requirements justify a
change.

## Purpose

This repository provides nvf-based Neovim configurations for daily use,
experimentation, and reuse across machines. The full configuration is the owner's
daily driver: their system flake consumes this repository's `main` branch through
an `nvf-config` input, and Home Manager installs its exposed wrapped output.
Treat changes on `main` as changes to that daily driver.

Support experiments through this repository's development shell, branches, and
additional output variants. Reliability and experimentation are both goals;
validate experiments before promoting them to the daily-driver configuration.

Both local terminals and remote sessions matter, usually through tmux. The
devops output targets headless servers and is primarily launched directly using
`nix run <remote-flake>#nvim-lean-devops`. Balance a familiar editing experience
and muscle memory against the dependencies downloaded for an ad hoc server edit.

## Current structure

- `flake.nix` exposes `nvim-lean-devops` and `nvim-generic-full`; the full profile
  is the default package, is included in the default development shell, and both
  profiles have build/startup checks.
- `nvfconfs/_groups/` contains the composable profile entry points for shared
  editing/workflow behavior and profile-specific languages, debugging, and
  extras.
- `nvfconfs/_common/` contains shared modules and Lua helpers. Language tools for
  the fresh-server baseline are isolated from the common LSP framework.
- The lean and full profile defaults compose groups rather than copying module
  import lists.
- `overlays/vim-plugins.nix` packages custom plugins and pinned forks.
- Declared platforms are `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`.
- `IMPROVEMENTS.md` records the completed review, decisions, measurements, and
  remaining validation limits.

## Goals

1. Protect user data. Save, encryption, and file-management helpers should report
   failures accurately and avoid destructive partial updates.
2. Keep the profiles coherent. Preserve familiar core editing behavior and muscle
   memory across full and devops profiles. Make differences intentional and
   understandable; allow additional variants when useful.
3. Preserve useful experiments. Custom plugins and forks are legitimate here;
   document their purpose rather than removing them solely for being custom.
4. Make dependencies explicit. Distinguish packaged utilities from tools expected
   from the host or a project's development environment.
5. Prioritize Linux, including local terminals and remote tmux sessions. Keep
   macOS largely functional through low-cost compatibility fixes, without
   requiring equal implementation or testing effort.
6. Prefer clear, maintainable configuration. Reuse helpers and nvf options when
   they express the desired behavior; use custom Lua where it adds real value.

## Profile composition

Use a cascaded, composable model in the flake: define reusable groups of settings
and include them in the profiles that need them. Keep shared behavior in one
place (DRY) so fixes propagate consistently and new output variants require
composition rather than copied configuration.

- Share core editing behavior, navigation, and keybindings across profiles.
- Group related capabilities into modules that profiles can include explicitly.
- Separate language/plugin settings groups from tool-package inclusion where the
  distinction is useful, while keeping the devops language group a complete,
  reusable baseline.
- Full is a strict language-capability superset of devops: its language group
  imports the complete devops baseline, then augments it with full-only servers,
  parsers, formatters, linters, and debuggers. Full-specific settings for a
  baseline language may extend or deliberately override one aspect, but must not
  accidentally discard that language's baseline capability.
- Keep group boundaries practical; avoid abstractions that make it harder to
  determine what a profile enables or pulls into its dependency closure.

## Profile and dependency policy

These policies describe the current defaults and the criteria for changing them.

- The devops language baseline is Nix, shell, YAML, JSON, and SQL. Preserve
  familiar navigation and editing while keeping the dependency footprint
  appropriate for direct `nix run` use on headless servers. Bundle completion,
  diagnostics, linting, and formatting tools so they work on a fresh server
  without a project environment. SQL is the deliberate lean exception: bundle
  Treesitter and SQLS, but keep SQLFluff formatting/linting in full because its
  Python closure is significant. Keep other heavy development tools out of the
  baseline and measure the closure impact when choosing implementations.
- Add every intentionally bundled devops language executable to
  `vim.extraPackages`. They must be available to `:!`, `vim.system()`, and
  terminals spawned by Neovim, in addition to nvf's absolute-path integrations.
  nvf appends these paths, preserving the inherited host/devenv path order.
- The full profile should prepare language support through editor plugins and
  settings so entering a direnv/devenv language environment works without
  additional Neovim configuration. It inherits the complete devops language and
  executable baseline before adding broader language support. Do not assume that
  project environments provide language servers: bundling broadly useful
  servers and editor services in full is often desirable, especially when
  standard nvf modules configure them reliably.
- Full-only bundled user-facing executables follow the same PATH rule. Add them
  through the module that owns the capability so full augments the inherited
  PATH without duplicating the devops package list. Do not treat arbitrary
  transitive runtime dependencies as user-facing tools.
- Choose full-profile tools selectively rather than applying one rule to every
  language-related executable. Consider how broadly the tool is useful, closure
  size, whether nvf integrates it cleanly, and whether it must match the project's
  language or dependency versions.
- As the default for full, keep nvf-provided language servers and debug adapters
  bundled. Their reliable, declarative integration is part of the editor profile.
  Source project-sensitive formatters and linters outside the inherited baseline
  from direnv/devenv, because their versions can affect diagnostics or rewrite
  project files.
- The inherited Nix/shell/YAML/JSON tools are an intentional always-available
  full-profile baseline because projects are unlikely to pin them. SQLFluff is a
  full-only always-available augmentation. Full's global Markdown capability and
  GNU Make support are additional bundled exceptions.
- Project-sensitive tools outside those documented exceptions must resolve from
  the active direnv/devenv environment. Avoid bundled fallbacks when they could
  silently analyze or modify a project with an incompatible toolchain or version.
- Go linting intentionally runs
  `go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest` with the
  Go toolchain selected by the project environment. Project rules use the same
  rolling command and commit a golangci configuration file to control behavior.
  Preserve `@latest` and do not bundle a separate `golangci-lint` executable. A
  golangci configuration file is useful but is not required for activation;
  projects without one use golangci-lint's defaults. Force `GOTOOLCHAIN=local`
  for this invocation so Go cannot silently download and switch to a toolchain
  newer than the one selected by the project environment.
- In full, bundle `golangci-lint-langserver` as a small editor service and
  configure it as an additional Go LSP. Its initialization command must invoke
  the intentional `go run ...@latest` command through the active direnv/devenv
  Go toolchain. Start this auxiliary server only in an active project Go
  environment; ordinary Go editing outside such an environment must remain
  quiet. Target golangci-lint v2; v1 compatibility is not required. Keep one
  source of golangci-lint diagnostics so the LSP and a separate `nvim-lint` job
  do not report every issue twice. Retain `nvim-lint` for other language
  diagnostics; remove only its Go binding and custom golangci-lint definition
  when the auxiliary LSP replaces them.
- Keep PATH-based integration available for environment-provided tools even when
  other editor services are bundled. The devops baseline is appended to PATH, so
  a host or devenv command can take precedence for manual shell use. nvf presets
  may still use their bundled absolute paths for stable editor integration.
- GNU Make is a permitted full-profile tooling exception. Nushell is an optional
  experiment; keep it disabled or commented out for now.
- General editor utilities are distinct from language development tooling. Keep
  their dependencies explicit and consider their cost for the devops profile.
- SOPS editing is a shared capability and must work in devops on a fresh server;
  bundle the `sops` executable in the relevant shared group. Keep decrypted-data
  handling failure-safe and avoid relying on a host-installed SOPS binary.
- The SOPS editing workflow may change when an alternative is safer or simpler
  while retaining convenient editing. Introduce such a change as an isolated,
  reviewable step with an easy Git rollback. Prefer a separate commit, branch, or
  temporarily selectable module over retaining unsafe dead code indefinitely.
- Full Markdown functionality is a globally available capability of the full
  profile. This includes its language/editor integration, preview support,
  Mermaid rendering, and related utilities; it need not depend on a project
  devenv. Its relatively large browser/rendering closure is intentional, though
  equivalent implementations may still be compared for size and reliability.
- Markdown-to-PDF commands and mappings belong to full's document-tooling group,
  not the devops profile. `md2pdf` is an optional command supplied by a separate
  pandoc flake in specific project environments; do not bundle it here. Its
  absence must not affect startup or ordinary Markdown editing.

## Tool-placement decisions

Treat closure size as one input, not a mandate to externalize tools. Standard nvf
language modules and presets are valuable because they provide tested adapter,
server, formatter, and debugger configuration. Keep them when replacing their
bundled executable would make configuration or daily use worse.

Before moving any working tool from a profile into direnv/devenv, demonstrate:

1. configuration parity: the repository still contains a clear, maintainable
   configuration with no per-project Neovim setup;
2. usage parity: commands, keybindings, prompts, automatic setup, and error
   behavior work at least as well in a representative project environment;
3. discoverability: the required environment executable is documented and a
   missing tool produces a clear, actionable result rather than a cryptic failure;
4. compatibility benefit or meaningful measured closure reduction.

If those conditions are not met, preserve the known-good bundled integration.
Prefer standard nvf configuration over custom Lua or wrapper machinery when the
only benefit would be a small closure reduction. Evaluate each tool by language
and role rather than assuming that all LSPs, formatters, linters, or adapters
belong on the same side of the boundary.

The current recommendation for Go and Python DAP is to keep nvf's bundled
adapters. A measured variant without their language adapters saved only about
120 MiB from a roughly 4.0 GiB full closure, while externalizing them would bypass
part of nvf's convenient language-level setup. Revisit this only if nvf gains
first-class external-command options or an equally good configuration is proven.

The custom `,` DAP-repeat behavior is session-scoped. It may override Vim's native
reverse `f`/`t` repeat while a debug session is active, but must restore native
`,` behavior outside DAP.

## Platform expectations

Linux is the primary target. Support both local terminals and remote sessions,
usually through tmux, including appropriate clipboard behavior.

macOS is used occasionally. Aim for basic usability without annoying errors,
using inexpensive platform guards and compatible defaults. Do not spend
substantial effort achieving parity or building macOS-specific features.

## Plugin choices and experiments

Consolidate clear plugin overlap and allow equivalent replacements when familiar
behavior and keybindings are preserved. Choose coherent shared defaults instead
of enabling competing implementations of the same feature unintentionally.
Keep experiments explicit, disabled by default or isolated in branches or output
variants until ready. Custom plugins and forks remain appropriate when they
provide useful behavior; consolidation is not a reason to remove unique features.

The devops profile intentionally retains the familiar shared editor experience:
nvim-tree, Telescope, barbar, the enabled mini modules, aerial, multicursors,
diffview, toggleterm/lazygit, SOPS editing, and the dashboard. Do not move these
to full solely to reduce plugin count. Optimize language/tool dependencies first,
then measure individual capabilities before proposing a replacement or removal.

Use `nvim-autopairs` as the shared autopair implementation and leave `mini.pairs`
disabled. The other enabled Mini modules remain part of the shared experience.

Lazygit and Neogit are both intentional. Lazygit belongs to the shared terminal/
Git workflow; Neogit is an additional full-profile interface. Do not consolidate
them merely because their capabilities overlap.

## Working on changes

- Inspect the relevant shared and profile-specific modules before editing.
- Check the pinned nvf source when option behavior or defaults matter. Do not
  assume current upstream documentation matches `flake.lock`.
- Keep dependency updates and unrelated refactoring separate from targeted fixes.
- Keep experimental workflow replacements reversible. When changing sensitive
  behavior such as SOPS editing, isolate the change so the previous known-good
  workflow can be restored quickly while the replacement is evaluated.
- Preserve established keybindings unless the task calls for changing them;
  explain changes that affect familiar editing behavior.
- Treat clipboard, SOPS, file copying, and format-on-save as user-visible behavior
  that needs careful verification.
- Record material findings and resolved items in `IMPROVEMENTS.md`; distinguish
  confirmed bugs, conditional issues, cleanup suggestions, and ruled-out concerns.
- This guidance does not require an additional approval step for routine,
  authorized work. Ask about preferences when they materially affect scope.

## Validation

- For Nix configuration changes, evaluate both profiles on affected platforms.
  For example: `nix eval --raw .#packages.x86_64-linux.nvim-lean-devops.drvPath`.
- Evaluation alone is not a build or runtime check. State which level was tested.
- For plugin/loading changes, use an appropriate build or startup smoke check
  when available. For behavior changes, exercise the affected workflow.
- For language integration changes, check behavior with tools supplied by a
  direnv/devenv environment as well as globally bundled editor services. Missing
  project-sensitive tools outside a development environment should not prevent
  ordinary editing or cause repeated intrusive errors.
- For devops dependency changes, check the baseline without a project environment
  and inspect the dependency impact. Full must inherit the updated baseline and
  retain its augmentations.
- For full-profile dependency changes, inspect closure impact and identify the
  largest additions. Size informs the decision but does not override intentional
  global features such as the complete Markdown workflow.
- Verify destructive failure paths only with disposable fixtures, never real
  secrets or user files.
- Avoid adding tests for documentation-only edits or checks that merely duplicate
  the implementation. Keep validation proportional to the change.

## Documentation

Keep the README useful for launching profiles, understanding their differences,
and discovering required host tools. Explain intentional exceptions near the
configuration they affect. Update this guidance when the owner changes the goals
or profile policies.
