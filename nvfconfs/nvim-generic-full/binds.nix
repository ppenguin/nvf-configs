{
  lib,
  pkgs,
  ...
}: let
  # inherit (inputs.nixpkgs)
  inherit (lib.nvim.binds) mkKeymap;
  mkKeymapD = mode: key: cmd: desc: mkKeymap mode key cmd {inherit desc;};
in {
  config.vim = {
    extraPackages = with pkgs; [
      jq # for the handy json processing binds below
    ];

    keymaps = [
      (mkKeymapD "n" "<M-Right>" "<C-w>l" "Go to right pane")
      (mkKeymapD "n" "<M-S-Right>" "<C-w>10<char-62>" "Pane 10c wider")
      (mkKeymapD "n" "<M-Left>" "<C-w>h" "go left pane")
      (mkKeymapD "n" "<M-S-Left>" "<C-w>10<lt>" "Pane 10c narrower")
      (mkKeymapD "n" "<M-Up>" "<C-w>k" "go up pane")
      (mkKeymapD "n" "<M-S-Up>" "<C-w>5+" "Pane 5l taller")
      (mkKeymapD "n" "<M-Down>" "<C-w>j" "go down pane")
      (mkKeymapD "n" "<M-S-Down>" "<C-w>5-" "Pane 5l shorter")
      # (mkKeymap "n" "<C-x>" "<CMD>bd<CR>" "Close current buffer") # NOTE: superseded by barbar
      # custom rendering (e.g. pandoc)
      (mkKeymapD "n" "<leader>mp" "<CMD>!md2pdf %<CR>" "make pdf with pandocomatic")
      (
        mkKeymapD "n" "<leader>mpo" "<CMD>!md2pdf --open %<CR>"
        "make pdf with pandocomatic and open in PDF viewer"
      )
      (
        mkKeymapD "n" "<leader>mpu" "<CMD>!md2pdf %<CR>"
        "make (update) pdf with pandocomatic"
      )
      # reload config
      (mkKeymapD "n" "<leader>rc" "<CMD>source $MYVIMRC<CR>" "reload config")
      # copy active buffer path to system clipboard
      (mkKeymapD "n" "<leader>bcp" ''<CMD>let @+=expand("%")<CR>'' "copy active buffer path to system clipboard")
      # handy
      (mkKeymapD ["n" "v"] "<leader>x" ''"_x'' "delete (cut without copy)")
      (mkKeymapD ["n" "v"] "<leader>d" ''"_d'' "delete <motion>/selection without copy")
      (mkKeymapD "n" "<leader>D" ''"_D'' "delete until EOL without copy")
      # (mkKeymap "n" "<leader>dd" ''"_dd'' "delete line without copy")
      (mkKeymapD "n" "<leader>:" "<CMD>Telescope commands<CR>" "Telescope commands")
      # copy/paste with clipboard
      (mkKeymapD ["n" "v"] "<leader>y" ''"+y'' "Yank <motion>/selection to system clipboard")
      (mkKeymapD "n" "<leader>p" ''"+p'' "Paste-after from system clipboard")
      (mkKeymapD "n" "<leader>P" ''"+P'' "Paste-at from system clipboard")

      # json utils
      (mkKeymapD "v" "<leader>js" "<CMD>!jq --sort-keys<CR>" "Sort json by keys")
      (
        mkKeymapD "v" "<leader>je"
        ''<CMD>!jq 'reduce to_entries[] as $kv ({}; setpath($kv.key|split("."); $kv.value))'<CR>''
        "Expand json keys"
      )
    ];
  };
}
