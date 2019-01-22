{ nixBoot, bootDir, writeText, runCommand }:

{ name, nixBoot, closure }:
let
  install = writeText "install.sh" ''
    #!/bin/sh
    set -e
    self="$(dirname "$0")"
    nix="${nixBoot}"
    bootDir="${bootDir}"
    mkdir -p $bootDir/store
    printf "Installing Nix to %s" "$bootDir" >&2
    for i in $(cd "$self/store" > /dev/null && echo ./*)
    do
      printf "." >&2
      i_tmp="$bootDir/store/$i.tmp"
      if [ -e "$i_tmp" ];
      then
        rm -rf "$i_tmp"
      fi
      if ! [ -e "$bootDir/store/$i" ]
      then
        cp -rp "$self/store/$i" "$i_tmp"
        chmod -R a-w "$i_tmp"
        chmod +w "$i_tmp"
        mv "$i_tmp" "$bootDir/store/$i"
        chmod -w "$bootDir/store/$i"
      fi
    done
    echo "" >&2

    echo "Registering Nix database..." >&2

    "$nix/bin/nix-store" --init
    "$nix/bin/nix-store" --load-db < "$self/reginfo"

    echo "Default configuration..." >&2

    mkdir -p $bootDir/etc/nix/
    cat > $bootDir/etc/nix/nix.conf <<END
    build-users-group =
    sandbox = false
    require-sigs = false
    END

    echo "Nix is installed at $nix/bin" >&2
  '';

in runCommand "${name}.tar.xz" {} ''
  mkdir package
  cp ${closure}/registration package/reginfo
  cp ${install} package/install.sh
  chmod -R +w package
  chmod +x package/install.sh

  dir=${name}-${nixBoot.version}
  tar cvJf $out \
    --absolute-names \
    --mode=u+rw,uga+r \
    --transform "s,$NIX_STORE,$dir/store,S" \
    --transform "s,package,$dir," \
    package \
    $(cat ${closure}/store-paths)
''

