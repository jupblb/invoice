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
            pandoc poppler_utils pre-commit pyright python3
            ruff
            tinymist typst typstyle
          ];
        });
      }
    );
}
