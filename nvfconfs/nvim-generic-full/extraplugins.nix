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
    extraPlugins =
      (builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {package = pkgs.vimPlugins."${name}";};
        })
        [
          "barbar-nvim"
          "nvim-spectre"
          "nvim-jqx"
          "nvim-dbee" # TODO: keybinds
        ]
      ))
      // {
        markdown-table-mode = {
          package = pkgs.vimUtils.buildVimPlugin {
            pname = "markdown-table-mode";
            version = "2025-07-13";
            src = pkgs.fetchFromGitHub {
              owner = "Kicamon";
              repo = "markdown-table-mode.nvim";
              rev = "bb1ea9b76c1b29e15e14806fdfbb2319df5c06f1";
              sha256 = "sha256-Pwsp9QQiADvzMjn2jSiQ/MPVCYjVnugKu55gbjvlYDk=";
            };
          };
        };
      };
  };
}
