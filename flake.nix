{
  description = "Coq support library for Sail instruction set models";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    coq-bbv.url = "github:maxkurze1/bbv";
  };

  outputs = { self, flake-utils, nixpkgs, coq-bbv, ... }:
    let
      coqSailPkg = { lib, mkCoqDerivation, coq, coq-bbv, version ? null, }: mkCoqDerivation rec {
        pname = "coq-sail";

        opam-name = "coq-sail";

        inherit version;
        defaultVersion = "0.19";
        release = {
          "0.19".src = lib.cleanSourceWith {
            src = lib.cleanSource ./src;
            filter = let inherit (lib) hasSuffix; in
              path: type:
                (! hasSuffix ".gitignore" path)
                && (! hasSuffix "flake.nix" path)
                && (! hasSuffix "flake.lock" path)
                && (! hasSuffix "_build" path);
          };
          # "0.16".rev = "0.16";
          # "0.17.1".rev = "0.17.1";
          # "0.17".rev = "0.17";
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
          devShells.default = packages.default;

          packages = rec {
            coq8_18-coq-sail = pkgs.coqPackages_8_18.coq-sail;
            coq8_19-coq-sail = pkgs.coqPackages_8_19.coq-sail;
            default = coq8_19-coq-sail;
          };

        }) // {
      overlays.default = final: prev:
        (nixpkgs.lib.mapAttrs
          (_: scope:
            scope.overrideScope (self: _: {
              coq-sail = self.callPackage coqSailPkg { };
            })
          )
          {
            inherit (prev) coqPackages_8_18 coqPackages_8_19;
          }
        );
    };
}
