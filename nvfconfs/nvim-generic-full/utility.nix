{
  config.vim.utility = {
    outline.aerial-nvim.enable = true;

    preview.markdownPreview = {
      enable = true;
      autoStart = false; # TODO: the plugin isn't even loaded without this, but we could probably to a keybind with `require`?
      broadcastServer = true; # probably nice to connect when doing remote edit
      # customIP = "0.0.0.0";
      # customPort = "15888";
      lazyRefresh = true;
    };

    multicursors.enable = true;

    diffview-nvim.enable = true;

    # motion = {
    #   flash-nvim.enable = true;
    #   precognition.enable = true;
    # };

    images = {
      image-nvim = {
        enable = true;
        setupOpts.backend = "kitty";
      };
    };

    # yazi-nvim = {enable = true;};

    direnv.enable = true;
  };
}
