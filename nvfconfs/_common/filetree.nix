{
  config.vim.filetree.nvimTree = {
    enable = true;
    mappings.toggle = "<leader>/";
    setupOpts = {
      git.enable = true;
      actions.open_file = {
        eject = true; # never open file in tree window
        resize_window = true;
        window_picker.enable = true;
      };
      # hijack_unnamed_buffer_when_opening = true;
      hijack_cursor = true;
      modified.enable = true;
      diagnostics.enable = true;
      renderer = {
        add_trailing = true;
        full_name = true;
        highlight_git = true;
        highlight_modified = "name";
        highlight_opened_files = "icon";
      };
      update_focused_file = {
        enable = true;
        update_root = false; # if set to true cd's to focused file (annoying)
      };
      # view.float.enable = true;
    };
  };
}
