{
  config.vim = {
    terminal.toggleterm = {
      enable = true;
      mappings.open = "<leader>,";
      setupOpts.direction = "float";
      lazygit = {
        enable = true; # default keybinding \gg
      };
    };

    maps.terminal."<leader>," = {
      action = "<CMD>ToggleTermToggleAll!<CR>";
      desc = "Close/hide toggleterm (without exiting the process)";
      silent = true;
    };
  };
}
