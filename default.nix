let
  bootDir = "/tmp/nix";
  nixpkgsP = ./nixpkgs;

in import ./bootstrap.nix {
  inherit bootDir;
  nixpkgs = import nixpkgsP {};
}
