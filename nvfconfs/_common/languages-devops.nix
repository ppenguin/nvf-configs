{pkgs, ...}: let
  complete = {
    enable = true;
    format.enable = true;
    lsp.enable = true;
    treesitter.enable = true;
  };
in {
  config.vim = {
    languages = {
      bash = complete // {extraDiagnostics.enable = true;};
      json = complete;
      nix =
        complete
        // {
          extraDiagnostics.enable = true;
          format = {
            enable = true;
            type = ["alejandra"];
          };
        };
      sql =
        complete
        // {
          format = {
            enable = true;
            type = ["sqlfluff"];
          };
          extraDiagnostics = {
            enable = true;
            types = ["sqlfluff"];
          };
        };
      yaml = complete;
    };

    # FormatNixUseNixfmt is available in both profiles. Alejandra is supplied by
    # the nvf language preset above; this adds the selectable alternative.
    extraPackages = [pkgs.nixfmt];
  };
}
