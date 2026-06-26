final: prev: {
  vimPlugins = prev.vimPlugins.extend (vfinal: vprev: {
    markdown-table-mode = final.vimUtils.buildVimPlugin {
      pname = "markdown-table-mode";
      version = "2025-07-13";
      src = final.fetchFromGitHub {
        owner = "Kicamon";
        repo = "markdown-table-mode.nvim";
        rev = "bb1ea9b76c1b29e15e14806fdfbb2319df5c06f1";
        sha256 = "sha256-Pwsp9QQiADvzMjn2jSiQ/MPVCYjVnugKu55gbjvlYDk=";
      };
    };

    markdown-preview-selim = final.vimUtils.buildVimPlugin {
      pname = "markdown-preview-selim";
      # PR: https://github.com/selimacerbas/markdown-preview.nvim/pull/28
      version = "unstable-2026-06-26";

      # original: owner = "selimacerbas"; rev = "29234edae5b8b7db5ae05061ff7197f95ef0ffd5"; hash = "sha256-WSB3oI8CbyGrSGu7HgLFKReQYKxxbc34ojGGvRWIvSQ=";
      src = final.fetchFromGitHub {
        owner = "icyveins7";
        repo = "markdown-preview.nvim";
        rev = "ca14e426f82e3dc645fe7522ed303c0994056af5";
        hash = "sha256-lSkoG3YOJo3HN5SxynHlFPbo9JBo8OihIXThExUj7pE=";
      };

      doCheck = false;
      doInstallCheck = false;

      meta = {
        description = "Live Markdown preview for Neovim with Mermaid diagrams, LaTeX math (KaTeX), scroll sync, and syntax highlighting";
        homepage = "https://github.com/selimacerbas/markdown-preview.nvim";
        license = final.lib.licenses.mit;
      };
    };

    live-server = final.vimUtils.buildVimPlugin {
      pname = "live-server";
      # PR: https://github.com/selimacerbas/live-server.nvim/pull/5
      version = "unstable-2026-06-26";

      # original: owner = "selimacerbas"; rev = "084d69b63610803c18ddd7541294d83ca748d1dc"; hash = "sha256-ig9UQ6FdEcU6ywfXzFdT7NYWY95CZ1dPS3QFH6/qKbg=";
      src = final.fetchFromGitHub {
        owner = "icyveins7";
        repo = "live-server.nvim";
        rev = "f4a43146b43d820247e9305a0737ee734c5adda1";
        hash = "sha256-D/4kD/mZzT4/Lkf+AG1LXhffK6L7BeuAz03I3aMf+NY=";
      };

      doCheck = false;
      doInstallCheck = false;

      meta = {
        description = "A tiny, zero-dependency local web server for Neovim";
        homepage = "https://github.com/selimacerbas/live-server.nvim";
        license = final.lib.licenses.mit;
      };
    };
  });
}
