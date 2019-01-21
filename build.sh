#!/bin/sh

set -eo pipefail

set -x
nix-build "$@" -A nixBoot -o nix-stage-1
set +x

mkdir -p "$bootDir/etc/nix"
if ! [ -f "$bootDir/etc/nix/nix.conf" ]
then
  set -x
  cat > "$bootDir/etc/nix/nix.conf" <<END
build-users-group =
sandbox = false
END
  set +x
fi

set -x
nix-stage-1/bin/nix-build "$@" -A nixBoot -o nix-stage-2
nix-stage-1/bin/nix-build "$@" -A nixInstaller -o link-nix-installer.tar.xz
[ -e nix-installer.tar.xz ] && rm nix-installer.tar.xz
cat link-nix-installer.tar.xz > nix-installer.tar.xz
nix-stage-1/bin/nix-build "$@" -A nixWithStdenvInstaller -o link-nix-stdenv-installer.tar.xz
[ -e nix-stdenv-installer.tar.xz ] && rm nix-stdenv-installer.tar.xz
cat link-nix-stdenv-installer.tar.xz > nix-stdenv-installer.tar.xz
set +x
