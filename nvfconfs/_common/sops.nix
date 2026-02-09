{lib, ...}: let
  inherit (lib.nvim.dag) entryAfter;
  inherit (lib.nvim.binds) mkBinding;
in {
  config.vim = {
    luaConfigRC.sops-edit =
      entryAfter ["toggleterm"]
      (builtins.readFile ./lua/sops_edit.lua);

    maps.normal = lib.mkMerge [
      (mkBinding "<leader>so" "<CMD>SopsEdit<CR>" "Edit current buffer with sops")
    ];
  };
}
