{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    inherit (self) outputs;

    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {pkgs = import nixpkgs {inherit system;};});

    forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
  in {
    formatter = forEachSupportedSystem ({pkgs}: pkgs.alejandra);
  };
}
