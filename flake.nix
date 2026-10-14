{
  description = "ZariShell: a dark Windows 7 Aero styled Quickshell desktop shell and greetd greeter";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs:
        let zs = pkgs.callPackage ./nix/packages.nix { };
        in {
          inherit (zs) shell greeter screenshot-region;
          default = zs.shell;
        });

      checks = forAll (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) shell greeter screenshot-region;
      });

      homeManagerModules.default = import ./nix/hm-module.nix;
      homeManagerModules.zarishell = self.homeManagerModules.default;
      nixosModules.default = import ./nix/nixos-module.nix;
      nixosModules.greeter = self.nixosModules.default;
    };
}
