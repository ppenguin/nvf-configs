{pkgs, ...}: {
  imports = [
    ../_common/binds.nix
    ../_common/common.nix
    ../_common/extraplugins.nix
    ../_common/filetree.nix
    ../_common/lsp.nix
    ../_common/mini.nix
    ../_common/sops.nix
    ../_common/term.nix
    ../_common/ui.nix
    ../_common/utility.nix
    ./extraplugins.nix
    ./lsp.nix
    ./ui.nix
    ./utility.nix
  ];

  config.vim = {
    extraPackages = with pkgs; [
      imagemagick # for image preview conversions
      mermaid-cli
    ];
  };

  git = {
    neogit.enable = true; # TODO: decide whether this stays and test it // replace lazygit?!
  };
}
