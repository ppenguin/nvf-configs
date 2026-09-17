{
  mkKeymapD,
  pkgs,
  ...
}: {
  config.vim = {
    extraPackages = [pkgs.lazygit];

    terminal.toggleterm = {
      enable = true;
      mappings.open = "<leader>,";
      setupOpts.direction = "float";
      lazygit = {
        enable = true; # default keybinding \gg
      };
    };

    keymaps = [
      (mkKeymapD "t" "<leader>," "<CMD>ToggleTermToggleAll!<CR>" "Close/hide toggleterm (without exiting the process)")
    ];
  };
}
