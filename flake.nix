{
  description = "Coq support library for Sail instruction set models";

  inputs = {
    nixpkgs.follows = "coq-bbv/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    coq-bbv.url = "github:maxkurze1/bbv";
  };

  outputs = { self, flake-utils, nixpkgs, coq-bbv, ... }:
    let
      coqSailPkg = { lib, mkCoqDerivation, coq, coq-bbv }: mkCoqDerivation rec {
        pname = "coq-sail";
        defaultVersion = "0.17";

        opam-name = "coq-sail";

        release."0.17" = {
          src = lib.const ./src;
        };

        propagatedBuildInputs = [
          coq-bbv
        ];

        makeFlags = [ "HAVE_OPAM_BBV=yes" ];
        installFlags = [ "DESTDIR=$(out)" "COQLIB=lib/coq/${coq.coq-version}" ];
      };

    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ coq-bbv.overlays.default self.overlays.default ];
          };
        in
        rec {
          devShells.default = packages.default.overrideAttrs (_: {
            shellHook = ''
              [[ -v SHELL ]] && exec "$SHELL"
            '';
          });

          packages = rec {
            coq8_18-coq-sail = pkgs.coqPackages_8_18.coq-sail;
            default = coq8_18-coq-sail;
          };

        }) // {
      overlays.default = final: prev:
        (nixpkgs.lib.mapAttrs
          (_: scope:
            scope.overrideScope' (self: _: {
              coq-sail = self.callPackage coqSailPkg { };
            })
          )
          {
            inherit (prev) coqPackages_8_18;
          }
        );
    };
}
