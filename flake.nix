{
  description = "Coq support library for Sail instruction set models";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    coq-bbv.url = "github:maxkurze1/bbv";
  };

  outputs = { self, flake-utils, nixpkgs, coq-bbv, ... }:
    let
      # flavor might be one of ["stdpp", "coq-bbv"]
      coqSailPkg = { lib, mkCoqDerivation, coq, coq-bbv, stdpp, version ? null, flavor ? "stdpp" }: mkCoqDerivation rec {
        pname = "coq-sail";

        # this name selects which dune package is build
        opam-name = if flavor == "coq-bbv" then "coq-sail" else "coq-sail-stdpp";

        inherit version;
        defaultVersion = "0.19.1";
        release = {
          "0.19.1".src = lib.cleanSourceWith {
            src = lib.cleanSource ./.;
            filter = let inherit (lib) hasSuffix; in
              path: type:
                (! hasSuffix ".gitignore" path)
                && (! hasSuffix "flake.nix" path)
                && (! hasSuffix "flake.lock" path)
                && (! hasSuffix "_build" path);
          };
          "0.16".rev = "0.16";
          "0.17.1".rev = "0.17.1";
          "0.17".rev = "0.17";
        };

        useDune = true;

        propagatedBuildInputs = [
          coq-bbv
          stdpp
        ];

        # makeFlags = [ "HAVE_OPAM_BBV=yes" ];
        # installFlags = [ "DESTDIR=$(out)" "COQLIB=lib/coq/${coq.coq-version}" ];
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
