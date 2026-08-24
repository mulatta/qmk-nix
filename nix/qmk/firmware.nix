{
  buildQmkPackage,
  lib,
}:

{
  extraMakeFlags ? [ ],
  firmwareFile,
  keyboard,
  keymap ? "nix",
  keymapMount ? "keyboards/${keyboard}/keymaps/${keymap}",
  keymapSource ? null,
  qmkFirmware,
  sourceMounts ? { },
  ...
}@args:

buildQmkPackage (
  (lib.removeAttrs args [
    "extraMakeFlags"
    "firmwareFile"
    "keyboard"
    "keymap"
    "keymapMount"
    "keymapSource"
    "qmkFirmware"
    "sourceMounts"
  ])
  // {
    inherit extraMakeFlags firmwareFile qmkFirmware;
    makeTarget = "${keyboard}:${keymap}";

    sourceMounts =
      sourceMounts
      // lib.optionalAttrs (keymapSource != null) {
        ${keymapMount} = keymapSource;
      };

    passthru = (args.passthru or { }) // {
      inherit keyboard keymap keymapMount;
    };
  }
)
