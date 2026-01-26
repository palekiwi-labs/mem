{
  description = "mem - CLI tool for managing AI agent artifacts in git repositories";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "mem";
            version = "0.1.0";
            
            src = ./.;
            
            nativeBuildInputs = [ pkgs.makeWrapper ];
            
            installPhase = ''
              mkdir -p $out/bin $out/share/mem
              
              # Bundle all source files and dependencies
              cp -r src $out/share/mem/
              
              # Create wrapper that sets up proper environment
              makeWrapper ${pkgs.nushell}/bin/nu $out/bin/mem \
                --add-flags "$out/share/mem/src/main.nu"
            '';
            
            meta = with pkgs.lib; {
              description = "CLI tool for managing AI agent artifacts in git repositories";
              homepage = "https://github.com/palekiwi-labs/mem";
              license = licenses.mit;
              platforms = platforms.unix;
              mainProgram = "mem";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nushell
          ];

          shellHook = ''
            echo "mem development environment"
            echo "Nushell version: $(nu --version)"
          '';
        };
      }
    );
}
