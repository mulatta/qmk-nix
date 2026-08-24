{
  lib,
  qmk,
  stdenvNoCC,
}:

{
  extraMakeFlags ? [ ],
  firmwareFile,
  makeTarget,
  qmkFirmware,
  sourceMounts ? { },
  ...
}@args:

let
  validMount =
    mount:
    mount != ""
    && !(lib.hasPrefix "/" mount)
    && lib.all (component: component != "" && component != "." && component != "..") (
      lib.splitString "/" mount
    );
  invalidMounts = lib.filter (mount: !validMount mount) (lib.attrNames sourceMounts);
  firmwareExtension = lib.last (lib.splitString "." firmwareFile);
  outputFile = "firmware.${firmwareExtension}";
in
assert lib.assertMsg (invalidMounts == [ ]) "sourceMounts must use normalized relative paths";
assert lib.assertMsg (
  builtins.baseNameOf firmwareFile == firmwareFile
) "firmwareFile must be a file name";
assert lib.assertMsg (firmwareExtension != firmwareFile) "firmwareFile must have an extension";
stdenvNoCC.mkDerivation (
  (lib.removeAttrs args [
    "extraMakeFlags"
    "firmwareFile"
    "makeTarget"
    "qmkFirmware"
    "sourceMounts"
  ])
  // {
    pname = args.pname or "qmk-firmware";
    version = args.version or "0-unstable";

    src = qmkFirmware;

    nativeBuildInputs = [ qmk ] ++ (args.nativeBuildInputs or [ ]);

    env = {
      SKIP_GIT = "yes";
      SKIP_VERSION = "yes";
    }
    // (args.env or { });

    postPatch =
      lib.concatLines (
        lib.mapAttrsToList (mount: source: ''
          rm -rf ${lib.escapeShellArg mount}
          mkdir -p ${lib.escapeShellArg mount}
          cp -r ${source}/. ${lib.escapeShellArg mount}/
          chmod -R u+w ${lib.escapeShellArg mount}
        '') sourceMounts
      )
      + (args.postPatch or "");

    buildPhase =
      args.buildPhase or ''
        runHook preBuild

        export HOME="$TMPDIR"
        make -j"$NIX_BUILD_CORES" ${lib.escapeShellArgs extraMakeFlags} ${lib.escapeShellArg makeTarget}

        runHook postBuild
      '';

    installPhase =
      args.installPhase or ''
        runHook preInstall

        artifact=${lib.escapeShellArg firmwareFile}
        if [ ! -s "$artifact" ]; then
          artifact=.build/${lib.escapeShellArg firmwareFile}
        fi
        if [ ! -s "$artifact" ]; then
          echo "QMK did not produce ${firmwareFile}" >&2
          exit 1
        fi

        install -Dm444 "$artifact" "$out/${outputFile}"

        runHook postInstall
      '';

    dontFixup = args.dontFixup or true;

    passthru = (args.passthru or { }) // {
      firmwareFile = outputFile;
      inherit makeTarget qmkFirmware;
    };
  }
)
