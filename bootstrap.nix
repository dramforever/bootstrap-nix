{ bootDir, nixpkgs }:

with nixpkgs;

let 
  buildInstaller = import ./build-installer.nix {
    inherit nixBoot bootDir writeText runCommand;
  };

in rec {
  nixBoot = nix.override {
    storeDir = "${bootDir}/store";
    stateDir = "${bootDir}/var";
    confDir = "${bootDir}/etc";
  };

  nixInstaller = buildInstaller {
    name = "nix";
    inherit nixBoot;
    closure = closureInfo {
      rootPaths = nixBoot.all;
    };
  };

  nixWithStdenvInstaller = buildInstaller {
    name = "nix-stdenv";
    inherit nixBoot;
    closure = closureInfo {
      rootPaths =
        let
          stdenvStages = curStage:
            [ curStage ]
              ++
                (if ! curStage.__bootPackages.__raw or false
                  then stdenvStages curStage.__bootPackages.stdenv
                  else []);
        in nixBoot.all ++ stdenvStages stdenv;
    };
  };
}
