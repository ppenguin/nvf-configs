{
  pkgs,
  mkKeymapD,
  ...
}: {
  config.vim = {
    extraPackages = with pkgs; [
      imagemagick
      mermaid-cli
    ];

    # md2pdf is intentionally supplied by a project-specific Pandoc flake.
    # Keeping the mapping here makes its absence harmless to normal editing.
    keymaps = [
      (mkKeymapD "n" "<leader>mp" "<CMD>!md2pdf %<CR>" "make PDF with pandocomatic")
      (
        mkKeymapD "n" "<leader>mpo" "<CMD>!md2pdf --open %<CR>"
        "make PDF with pandocomatic and open it"
      )
      (mkKeymapD "n" "<leader>mpu" "<CMD>!md2pdf %<CR>" "update PDF with pandocomatic")
    ];
  };
}
