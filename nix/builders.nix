{ callPackage }:

rec {
  buildQmkPackage = callPackage ./qmk/package.nix { };

  buildQmkFirmware = callPackage ./qmk/firmware.nix {
    inherit buildQmkPackage;
  };
}
