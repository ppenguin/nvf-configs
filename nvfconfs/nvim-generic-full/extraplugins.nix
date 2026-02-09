{pkgs, ...}: {
  config.vim = {
    # here we can provide custom setup
    extraPlugins =
      (builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {package = pkgs.vimPlugins."${name}";};
        })
        [
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
