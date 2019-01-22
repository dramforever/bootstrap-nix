#!/bin/sh

set -eo pipefail

if ! [ -d nixpkgs ]
then
  echo "Nixpkgs required to build" >&2
  echo "Get a revision of nixpkgs before building" >&2
  exit 1
fi

mkdir -p build

set -x
nix-build "$@" -A nixBoot -o build/nix-stage-1
set +x

mkdir -p "/tmp/nix/etc/nix"
if ! [ -f "/tmp/nix/etc/nix/nix.conf" ]
then
  set -x
  cat > "/tmp/nix/etc/nix/nix.conf" <<END
build-users-group =
sandbox = false
END
  set +x
fi

set -x
build/nix-stage-1/bin/nix-build "$@" -A nixBoot -o build/nix-stage-2
build/nix-stage-1/bin/nix-build "$@" -A nixInstaller -o build/link-nix-installer.tar.xz
[ -e build/nix-installer.tar.xz ] && rm build/nix-installer.tar.xz
cat build/link-nix-installer.tar.xz > build/nix-installer.tar.xz
build/nix-stage-1/bin/nix-build "$@" -A nixWithStdenvInstaller -o build/link-nix-stdenv-installer.tar.xz
[ -e build/nix-stdenv-installer.tar.xz ] && rm build/nix-stdenv-installer.tar.xz
cat build/link-nix-stdenv-installer.tar.xz > build/nix-stdenv-installer.tar.xz
set +x
