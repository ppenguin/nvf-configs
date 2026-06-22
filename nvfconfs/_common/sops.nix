{
  lib,
  mkKeymapD,
  ...
}: let
  inherit (lib.nvim.dag) entryAfter;
in {
  config.vim = {
    luaConfigRC.sops-edit =
      entryAfter ["toggleterm"]
      (builtins.readFile ./lua/sops_edit.lua);

    keymaps = [
      (mkKeymapD "n" "<leader>so" "<CMD>SopsEdit<CR>" "Edit current buffer with sops")
    ];
  };
}
