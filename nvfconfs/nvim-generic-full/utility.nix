{
  config.vim.utility = {
    preview.markdownPreview = {
      enable = true;
      autoStart = false;
      broadcastServer = true; # probably nice to connect when doing remote edit
      # customIP = "0.0.0.0";
      # customPort = "15888";
      lazyRefresh = true;
    };

    images = {
      image-nvim = {
        enable = true;
        setupOpts.backend = "kitty";
      };
    };
  };
}
