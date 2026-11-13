# nix eval --offline --impure --json --expr 'import ./tests/pam-home-manager.nix { homeManager = /path/to/home-manager; }'
{ homeManager }:
let
  flake = builtins.getFlake (toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
  lib = pkgs.lib;
  environment = settings: (import (homeManager + "/modules") {
    inherit pkgs;
    configuration = {
      imports = [ flake.homeManagerModules.default ];
      home = { username = "pam-test"; homeDirectory = "/home/pam-test"; stateVersion = "26.05"; };
      programs.zarishell = { enable = true; } // settings;
    };
  }).config.systemd.user.services.quickshell.Service.Environment;
in
assert lib.assertMsg (lib.elem "ZARISHELL_PAM_SERVICE=hyprlock" (environment { }))
  "Home Manager must preserve the existing hyprlock PAM policy by default";
assert lib.assertMsg (lib.elem "ZARISHELL_PAM_SERVICE=custom-lock" (environment { pamService = "custom-lock"; }))
  "Home Manager must pass a custom PAM policy to the real Quickshell service";
"PASS Home Manager PAM regression tests"
