{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    semantic-lang-gen.url = "github:bglgwyng/semantic-lang-gen";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          ghc = "ghc965";
          lang = "go";
          Lang = "Go";
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (_: prev: { haskellPackages = prev.haskell.packages."${ghc}"; })
              inputs.semantic-lang-gen.overlay
              (final: prev:
                let
                  pkgs = final.pkgs;
                in
                {
                  haskellPackages = prev.haskellPackages.override
                    (old: {
                      overrides = pkgs.lib.composeManyExtensions [
                        (old.overrides or (_: _: { }))
                        (pkgs.haskell.lib.packageSourceOverrides { semantic-lang-gen-example = ./semantic-lang-gen-example; })
                        (final: prev: {
                          "tree-sitter-${lang}" = inputs.semantic-lang-gen.generate-tree-sitter-lang
                            {
                              inherit pkgs Lang;
                              parser = inputs.semantic-lang-gen.generate-parser
                                {
                                  inherit pkgs lang;
                                  grammar-js = ./grammar.js;
                                };
                            };
                          "semantic-${lang}" = inputs.semantic-lang-gen.generate-semantic-lang {
                            inherit pkgs;
                            tree-sitter-lang = final."tree-sitter-${lang}";
                          };
                        })
                      ];
                    });
                  # ... things you need to patch ...
                })
            ];
            config = {
              allowUnfree = true;
              allowBroken = true;
            };
          };
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages.default = pkgs.haskellPackages.semantic-lang-gen-example;
          packages."tree-sitter-${lang}" = pkgs.haskellPackages."tree-sitter-${lang}";
          packages."semantic-${lang}" = pkgs.haskellPackages."semantic-${lang}";

          # devShells.default = import ./develop.nix { inherit pkgs; };
          devShells.default = pkgs.mkShell {
            buildInputs =
              with pkgs;
              haskellPackages.semantic-lang-gen-example.env.nativeBuildInputs
              ++
              [
                tree-sitter
                nodejs_22
                (haskellPackages.ghcWithPackages (p: with p; [
                  haskell-language-server
                  ghcid
                ]))
              ];
          };

        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
