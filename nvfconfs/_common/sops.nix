{
  lib,
  pkgs,
  mkKeymapD,
  ...
}: let
  inherit (lib.nvim.dag) entryAfter;
in {
  config.vim = {
    extraPackages = [pkgs.sops];

    luaConfigRC.sops-edit = entryAfter ["toggleterm"] ''
      local sops_binary = ${builtins.toJSON (lib.getExe pkgs.sops)}
      ${builtins.readFile ./lua/sops_edit.lua}
    '';

    keymaps = [
      (mkKeymapD "n" "<leader>so" "<CMD>SopsEdit<CR>" "Edit current buffer with sops")
    ];
  };
}
