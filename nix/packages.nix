# Package set; call with `pkgs.callPackage ./nix/packages.nix { }`.
{ lib, runCommandLocal, writeShellScriptBin, hyprpicker, slurp, grim, wl-clipboard, libnotify, coreutils }:
let
  src = lib.cleanSource ../.;
in
rec {
  # The desktop shell config dir (quickshell -p / programs.quickshell.configs).
  shell = runCommandLocal "zarishell-shell" { } ''
    cp -rL ${src}/shell $out
  '';

  # Greeter config dir. Shared QML is symlinked to ../shell in the repo and
  # dereferenced here so the greeter keeps its own Wallpaper.qml.
  # `wallpaper`: optional image baked in (null = Theme gradient).
  mkGreeter = { wallpaper ? null }: runCommandLocal "zarishell-greeter" { } ''
    cp -rL ${src}/greeter $out
    chmod -R u+w $out
    ${lib.optionalString (wallpaper != null) ''
      cp ${wallpaper} $out/wallpaper
      substituteInPlace $out/Wallpaper.qml --replace-fail "hasWallpaper: false" "hasWallpaper: true"
    ''}
  '';
  greeter = mkGreeter { };

  # Region screenshot (frozen screen, slurp, grim, copy, notify).
  screenshot-region = writeShellScriptBin "screenshot-region" ''
    set -eu
    export PATH=${lib.makeBinPath [ hyprpicker slurp grim wl-clipboard libnotify coreutils ]}:$PATH
    ${builtins.readFile ./scripts/screenshot-region.sh}
  '';
}
