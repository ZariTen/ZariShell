# nix eval --offline --impure --json --file tests/pam-nixos.nix
let
  flake = builtins.getFlake (toString ../.);
  nixpkgs = flake.inputs.nixpkgs.outPath;
  lib = flake.inputs.nixpkgs.lib;
  evaluate = settings: (import (nixpkgs + "/nixos/lib/eval-config.nix") {
    system = builtins.currentSystem;
    modules = [ flake.nixosModules.default {
      system.stateVersion = "26.05";
      services.zarishell = settings;
    } ];
  }).config;
  disabled = evaluate { };
  enabled = evaluate { pam.enable = true; };
  renamed = evaluate { pam = { enable = true; serviceName = "custom-lock"; }; };
  policy = enabled.security.pam.services.zarishell;
in
assert lib.assertMsg (!(disabled.security.pam.services ? zarishell)) "PAM provisioning must be opt-in";
assert lib.assertMsg (!enabled.services.greetd.enable) "Lock PAM must not enable the greeter";
assert lib.assertMsg (policy.unixAuth && !policy.allowNullPassword && lib.hasInfix "pam_unix.so" policy.text)
  "Dedicated lock PAM policy must support password authentication without null passwords";
assert lib.assertMsg (enabled.environment.etc ? "pam.d/zarishell") "PAM policy must be installed under /etc/pam.d";
assert lib.assertMsg ((renamed.security.pam.services ? custom-lock) && !(renamed.security.pam.services ? zarishell))
  "PAM service rename must provision only the requested service";
"PASS NixOS PAM regression tests"
