{lib, ...}: let
  inherit (lib.nvim.binds) mkKeymap;
  mkKeymapD = mode: key: cmd: desc: mkKeymap mode key cmd {inherit desc;};
in {
  config.vim = {
    mini = {
      # clue.enable = true;
      # files.enable = true;
      # jump2d.enable = true;
      ai.enable = true;
      # animate.enable = true;
      icons.enable = true;
      indentscope.enable = true;
      jump.enable = true;
      map.enable = true;
      operators.enable = true;
      pairs.enable = true;
      splitjoin.enable = true;
      surround.enable = true;
    };
    keymaps = [
      (mkKeymapD "n" "<leader>imt" "<CMD>lua MiniMap.toggle()<CR>" "mini-map toggle")
      (mkKeymapD "n" "<leader>ims" "<CMD>lua MiniMap.toggle_side()<CR>" "mini-map toggle side (left)")
    ];
  };
}
