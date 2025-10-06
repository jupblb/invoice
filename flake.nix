{
  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem(
    system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell({
          buildInputs = with pkgs; [
            gnumake
            liberation_ttf
            pandoc poppler_utils pre-commit pyright python3
            ruff
            tinymist typst typstyle
          ];

          shellHook = ''
            export TYPST_FONT_PATHS="${pkgs.liberation_ttf}/share/fonts"
          '';
        });
      }
    );
}
