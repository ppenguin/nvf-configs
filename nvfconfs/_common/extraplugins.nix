{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.nvim.binds) mkKeymap;
  mkKeymapD = mode: key: cmd: desc: mkKeymap mode key cmd {inherit desc;};
in {
  config.vim = {
    keymaps = [
      # Barbar:
      (mkKeymapD "n" "<C-S-Right>" "<CMD>BufferNext<CR>" "Next buffer [barbar]")
      (mkKeymapD "n" "<C-S-Left>" "<CMD>BufferPrevious<CR>" "Previous buffer [barbar]")
      (mkKeymapD "n" "<C-x>" "<CMD>BufferClose<CR>" "Close buffer / focused tab [barbar]")
      (mkKeymapD "n" "<C-x>o" "<CMD>BufferCloseAllButCurrent<CR>" "Close all other buffers [barbar]")
      (mkKeymapD "n" "<C-x>l" "<CMD>BufferCloseBuffersLeft<CR>" "Close all buffers to the left [barbar]")
      (mkKeymapD "n" "<C-x>r" "<CMD>BufferCloseBuffersRight<CR>" "Close all buffers to the right [barbar]")
      (mkKeymapD "n" "<C-p>" "<CMD>BufferPick<CR>" "Pick buffer [barbar]")
      (mkKeymapD "n" "<C-p>d" "<CMD>BufferPickDelete<CR>" "Pick buffer to delete (close) [barbar]")
    ];

    # luaConfigRC = {
    #   hi_barbar = ''
    #     vim.cmd[[highlight BufferCurrent gui=bold guifg=#${config.lib.stylix.colors.base0C} ]]
    #   '';
    # };

    # here we can provide custom setup
    extraPlugins = builtins.listToAttrs (
      map (name: {
        inherit name;
        value = {package = pkgs.vimPlugins."${name}";};
      })
      [
        "barbar-nvim"
      ]
    );
  };
}
