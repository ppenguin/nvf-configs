# Shared helpers exposed as module arguments, so any module in this repo can
# request them via its argument set, e.g. `{mkKeymapD, ...}:`.
{lib, ...}: {
  _module.args.mkKeymapD = mode: key: cmd: desc:
    lib.nvim.binds.mkKeymap mode key cmd {inherit desc;};
}
