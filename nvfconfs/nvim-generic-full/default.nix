{...}: {
  imports = [
    ../_groups/editing-core.nix
    ../_groups/workflow-core.nix
    ../_groups/languages-full.nix
    ../_groups/debug-full.nix
    ../_groups/extras-full.nix
  ];

  config.vim = {
    git = {
      neogit = {
        enable = true;
        setupOpts = {
          graph_style = "kitty";
        };
      };
    };
  };
}
