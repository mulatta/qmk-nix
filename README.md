# qmk-nix

Reusable Nix builders for compiling out-of-tree QMK firmware.

Architecture follows [`zmk-nix`](https://github.com/lilyinstarlight/zmk-nix): one `buildersFor` factory feeds `legacyPackages` and an optional overlay. Firmware repositories and vendor policy remain explicit downstream inputs.

## Builder

```nix
qmk-nix.legacyPackages.${system}.buildQmkFirmware {
  qmkFirmware = qmkSource;
  keyboard = "vendor/keyboard";
  keymap = "dots";
  keymapSource = ./firmware;

  sourceMounts = {
    "lib/chibios" = chibiosSource;
  };

  firmwareFile = "vendor_keyboard_dots.bin";
}
```

`buildQmkFirmware` replaces declared source mounts in a writable QMK tree, sets reproducible QMK build flags, runs QMK's Make target, and verifies the exact requested artifact. Output uses a stable `firmware.<extension>` name.

Vendor-specific source pins and flash tools belong in downstream adapters. ZSA consumers should assemble the ZSA QMK tree with its pinned modules, then flash the resulting `.bin` explicitly with Zapp.
