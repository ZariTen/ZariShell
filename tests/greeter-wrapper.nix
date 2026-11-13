# nix eval --offline --option allow-import-from-derivation false --impure --json --file tests/greeter-wrapper.nix
let
  flake = builtins.getFlake (toString ../.);
  pkgs = flake.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  inherit (pkgs) lib;
  # Evaluate the real module without building its runtime packages or IFD.
  evaluate = overrides: (lib.evalModules {
    specialArgs.pkgs = pkgs // { writeShellScript = name: text: text; };
    modules = [ (import ../nix/nixos-module.nix) {
      options = {
        services.greetd = lib.mkOption { type = lib.types.attrs; default = {}; };
        services.displayManager.sessionData.desktops = lib.mkOption { type = lib.types.str; default = "/fixture sessions"; };
        systemd.tmpfiles.rules = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
        users.users.greeter.extraGroups = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
        security.pam.services = lib.mkOption { type = lib.types.attrs; default = {}; };
      };
      config.services.zarishell.greeter = { enable = true; } // overrides;
    } ];
  }).config;
  odd = "space ' \" \\ $HOME $(probe) ; %n";
  values = {
    minUid = 100000;
    maxUid = 300000;
    stateDir = "/var/lib/${odd}";
    mainMonitor = odd;
    sessionCommand = "session --label '${odd}'";
    sessionName = odd;
    hostLabel = odd;
    cursor.name = odd;
  };
  config = evaluate values;
  wrapper = config.services.greetd.settings.default_session.command;
  controls = [ "\n" "\r" "\t" (builtins.fromJSON ''"\u0001"'') (builtins.fromJSON ''"\u007f"'') ];
  keys = [ "stateDir" "mainMonitor" "sessionCommand" "sessionName" "hostLabel" ];
  rejected = key: value:
    !(builtins.tryEval (builtins.deepSeq (evaluate { ${key} = value; }).services.greetd.settings.default_session.command true)).success;
in
assert lib.assertMsg (lib.hasInfix "export HOME=${lib.escapeShellArg values.stateDir}" wrapper)
  "Greeter HOME must quote stateDir as a single literal shell value";
assert lib.assertMsg (builtins.all (key: builtins.all (control: rejected key ("/unsafe" + control)) controls) keys)
  "Greeter string options must reject control characters";
assert lib.assertMsg (builtins.all (control:
  !(builtins.tryEval (builtins.deepSeq (evaluate { cursor.name = "cursor" + control; }).services.greetd.settings.default_session.command true)).success
) controls) "Cursor name must reject control characters";
assert lib.assertMsg (builtins.all (settings:
  !(builtins.tryEval (builtins.deepSeq (evaluate settings).services.greetd.settings.default_session.command true)).success
) [ { minUid = -1; } { maxUid = 4294967295; } { minUid = 3000; maxUid = 2000; } ]) "Invalid or inverted UID bounds must be rejected";
{
  inherit wrapper;
  rule = builtins.head config.systemd.tmpfiles.rules;
  expected = values;
}
