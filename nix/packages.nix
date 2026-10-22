# Package set; call with `pkgs.callPackage ./nix/packages.nix { }`.
{ lib, stdenv, runCommandLocal, writeShellScriptBin, hyprpicker, slurp, grim, wl-clipboard, libnotify, coreutils }:
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

  # NVIDIA stats for the system monitor (shell/scripts/gpustat.sh). Loads
  # libnvidia-ml at runtime, so it builds and runs fine on non-NVIDIA hosts.
  nvml = stdenv.mkDerivation {
    pname = "zarishell-nvml";
    version = "0.1";
    src = ./nvml;
    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      $CC -O2 -Wall -Wextra -o zarishell-nvml zarishell-nvml.c
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 zarishell-nvml $out/bin/zarishell-nvml
      runHook postInstall
    '';
    meta.platforms = lib.platforms.linux;
  };
}
